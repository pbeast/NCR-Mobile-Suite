//Test change by Michalich
Parse.Cloud.job("cleanAssociations", function(request, status) {
	var moment = require('moment');

	Parse.Cloud.useMasterKey();

	var threshold = new Date(moment().subtract('h', 1).format());

	var receiptsQuery = new Parse.Query("associationMap");
	receiptsQuery.lessThanOrEqualTo("updatedAt", threshold);

	receiptsQuery.each(function(association) {
		return association.destroy();
	}).then(function() {
		// Set the job's success status
		status.success("associationMap cleanUp completed successfully.");
	}, function(error) {
		// Set the job's error status
		status.error("associationMap cleanUp failed: " + error.message);
	});
});

Parse.Cloud.define("createAssociation", function(request, response) {

	if (request.params.installationId == undefined) {
		response.error("installationId is mandatory parameter");
		return
	}

	var Counter = Parse.Object.extend("Counter");
	var queryCounter = new Parse.Query(Counter);

	queryCounter.get("EHpEnGFBmg", {
		success: function(object) {
			object.increment('sequence');
			if (object.get('sequence') == 100000)
				object.increment('sequence', -100000);

			object.save(null, {
				success: function(sequenceObject) {
					console.log(sequenceObject);
					console.log(sequenceObject.get("sequence"));

					var associationMap = Parse.Object.extend("associationMap");
					var newAssociation = new associationMap();

					newAssociation.save({
						"syncCode": sequenceObject.get("sequence"),
						"installationId": request.params.installationId,
						"user": request.user
					}, {
						success: function(association) {
							response.success({
								syncCode: sequenceObject.get("sequence")
							});
						},
						error: function(association, error) {
							response.error('Failed to create new object, with error code: ' + error.message);
						}
					});
				},
				error: function(error) {
					console.log(error);
					response.error(error);
				}
			});
		},
		error: function(error) {
			console.log(error);
			response.error(error);
		}
	});
});

var createReceiptAndSendPush = function(response, association, receipt, total, storeAddress, retailer) {
	var Receipts = Parse.Object.extend("Receipts");
	var receipt = new Receipts();

	var installationId = association.get("installationId");

	receipt.save({
		"installationId": installationId,
		"user": association.get("user"),
		"receipt": receipt,
		"total": total,
		"storeAddress": storeAddress,
		"retailer": retailer
	}, {
		success: function(receipt) {
			console.log("Receipt stored successful");

			association.destroy();

			var query = new Parse.Query(Parse.Installation);
			query.equalTo('installationId', installationId);
			Parse.Push.send({
				where: query,
				data: {
					alert: "New Receipt is ready",
					title: "NCR Mobile Suite",
					badge: "1",
					pushReason: 0 //New Receipt
				}
			}, {
				success: function() {
					console.log("Push was successful");
					response.success("Receipt published successfully; Push was successful");
				},
				error: function(error) {
					console.log("Push was unsuccessful: " + error.message);
					response.success("Receipt published successfully; Push was unsuccessful: " + error.message);
				}
			});
		},
		error: function(receipt, error) {
			response.error('Failed to create new receipt, with error code: ' + error.message);
		}
	});
}

Parse.Cloud.define("publishReceipt", function(request, response) {
	if (request.params.syncCode == undefined) {
		response.error("pinCode is mandatory parameter");
		return
	}

	if (request.params.receipt == undefined) {
		response.error("receipt is mandatory parameter");
		return
	}

	if (request.params.total == undefined) {
		response.error("total is mandatory parameter");
		return
	}

	if (request.params.retailerId == undefined) {
		response.error("retailerId is mandatory parameter");
		return
	}

	if (request.params.storeAddress == undefined) {
		response.error("storeAddress is mandatory parameter");
		return
	}

	var Retailer = Parse.Object.extend("Retailer");
	var retailerQuery = new Parse.Query(Retailer);
	retailerQuery.get(request.params.retailerId, {
		success: function(retailer) {
			console.log("Found retailer");

			var associationQuery = new Parse.Query("associationMap");

			var syncCode = parseInt(request.params.syncCode, 10)
			associationQuery.equalTo("syncCode", syncCode);
			associationQuery.descending("createdAt");

			associationQuery.first({
				success: function(association) {
					console.log("Found association");

					var r = createReceiptAndSendPush(
						response,
						association,
						request.params.receipt,
						request.params.total,
						request.params.storeAddress,
						retailer
					);
				},
				error: function(error) {
					response.error("Failed to find association. Error=" + error.message);
				}
			});
		},
		error: function() {
			response.error("Retailer not found. Error=" + error.message);
		}
	});
});


Parse.Cloud.define("fetchReceiptByPinCode", function(request, response) {
	if (request.params.pinCode == undefined) {
		response.error("pinCode is mandatory parameter");
		return
	}

	var pinCode = parseInt(request.params.pinCode, 10);
	console.log("pinCode: " + pinCode);
	// return;

	var receiptsQuery = new Parse.Query("Receipts");

	receiptsQuery.equalTo("pinCode", pinCode);
	receiptsQuery.first({
		success: function(result) {
			if (result.get("state") != 1) {
				response.error("receipt still not published");
				return;
			}

			response.success(result.get("receipt"));
		},
		error: function() {
			response.error("receipt lookup failed");
		}
	});
});

Parse.Cloud.define("unAssociateInstallationWithUser", function(request, response) {
	if (request.params.installationId == undefined) {
		response.error("installationId is mandatory parameter");
		return
	}

	Parse.Cloud.useMasterKey();

	var installationsQuery = new Parse.Query(Parse.Installation);
	installationsQuery.equalTo("installationId", request.params.installationId);
	installationsQuery.first({
		success: function(object) {
			object.unset('user');
			object.save();

			response.success("");
		},
		error: function(error) {
			response.error("installation lookup failed:" + error.message);
		}
	});
});

Parse.Cloud.define("associateInstallationWithUser", function(request, response) {
	if (request.params.installationId == undefined) {
		response.error("installationId is mandatory parameter");
		return
	}

	if (request.user == undefined) {
		response.error("no logged-in user");
		return
	}

	Parse.Cloud.useMasterKey();

	var installationsQuery = new Parse.Query(Parse.Installation);
	installationsQuery.equalTo("installationId", request.params.installationId);
	installationsQuery.first({
		success: function(object) {
			object.set('user', request.user);
			object.save();

			var receiptsQuery = new Parse.Query("Receipts");
			receiptsQuery.equalTo("installationId", request.params.installationId);
			receiptsQuery.equalTo("user", null);
			receiptsQuery.each(function(receipt) {
				receipt.set('user', request.user);
				receipt.save();
			}).then(function() {
					response.success("");
				},
				function(error) {
					response.error("receipts lookup failed:" + error.message);
				});
		},
		error: function(error) {
			response.error("receipts lookup failed:" + error.message);
		}
	});
});

Parse.Cloud.define("fetchReceiptsByInstallationId", function(request, response) {
	if (request.params.installationId == undefined) {
		response.error("installationId is mandatory parameter");
		return
	}

	console.log(request.params.lastFetchTime);

	var receiptsQuery = new Parse.Query("Receipts");

	receiptsQuery.equalTo("installationId", request.params.installationId);
	receiptsQuery.equalTo("user", null);

	if (request.params.lastFetchTime != "" && request.params.lastFetchTime != undefined)
		receiptsQuery.greaterThan("createdAt", request.params.lastFetchTime);

	receiptsQuery.include("retailer");
	receiptsQuery.equalTo("state", 1);
	receiptsQuery.descending("createdAt");

	receiptsQuery.find({
		success: function(results) {
			if (results.length == 0) {
				response.success("No data");
				return;
			}

			response.success(results);
		},
		error: function(error) {
			response.error("receipts lookup failed:" + error.message);
		}
	});
});

Parse.Cloud.define("fetchReceiptsByUser", function(request, response) {

	Parse.Cloud.useMasterKey();

	console.log(request.user);
	console.log(request.params.lastFetchTime);


	var receiptsQuery = new Parse.Query("Receipts");
	if (request.params.lastFetchTime != "" && request.params.lastFetchTime != undefined)
		receiptsQuery.greaterThan("createdAt", request.params.lastFetchTime);
	receiptsQuery.equalTo('user', request.user);
	receiptsQuery.include("retailer");
	receiptsQuery.descending("createdAt");

	receiptsQuery.find({
		success: function(results) {
			if (results.length == 0) {
				response.success("No receipts found for user");
				return;
			}

			response.success(results);
		},
		error: function(error) {
			response.error("receipts lookup failed:" + error.message);
		}
	});


	/*
		var installationsQuery = new Parse.Query(Parse.Installation);
		installationsQuery.equalTo('user', request.user); 
		installationsQuery.select("installationId");
		installationsQuery.find({
			success: function(userInstallations) {
		    	if (userInstallations.length == 0){
					response.error("No installations for user");
					return;
		    	}

		    	//console.log(userInstallations);

				var receiptsQuery = new Parse.Query("Receipts");
				if (request.params.lastFetchTime != "" && request.params.lastFetchTime != undefined)
					receiptsQuery.greaterThan("createdAt", request.params.lastFetchTime);
				var installationIds = [];
				for (var i = 0; i < userInstallations.length; i++) { 
					installationIds.push(userInstallations[i].get("installationId"));
	    		}

				console.log(installationIds);

				receiptsQuery.containedIn("installationId", installationIds);
				receiptsQuery.include("retailer");
				receiptsQuery.equalTo("state", 1);
				receiptsQuery.descending("createdAt");

				receiptsQuery.find({
				    success: function(results) {
				    	if (results.length == 0){
							response.success("No receipts found for user");
							return;
				    	}

				   	    response.success(results);
			       	},
				    error: function(error) {
				        response.error("receipts lookup failed:" + error.message);
				    }
				});
	       	},
		    error: function(error) {
		        response.error("User installations lookup failed:" + error.message);
		    }
		});
	*/
});

Parse.Cloud.define("confirmPayPalPreapprovalKey", function(request, response) {
	if (request.user == undefined) {
		response.error("You have to login first");
		return
	}
	var paymentMethodQuery = new Parse.Query("PaymentMethod");
	paymentMethodQuery.equalTo("user", request.user);
	paymentMethodQuery.equalTo("type", 0); //PayPal
	paymentMethodQuery.first({
		success: function(paymentMethod) {
			if (paymentMethod == undefined) {
				response.error("Payment method not found");
			} else {
				var connectionData = paymentMethod.get("connectionData");
				connectionData["confirmed"] = true;

				paymentMethod.set("connectionData", connectionData);
				paymentMethod.save();
				response.success();
			}
		},
		error: function(error) {
			console.log("Failed to update Payment Method: " + error.message);
			response.error("Failed to update Payment Method: " + error.message);
		}
	});
});

Parse.Cloud.define("getPayPalPreapprovalKey", function(request, response) {
	var moment = require('moment');

	if (request.user == undefined) {
		response.error("You have to login first");
		return
	}

	var now = moment();
	var futureDate = now.add('y', 1);

	Parse.Cloud.httpRequest({
		method: 'POST',
		url: 'https://svcs.sandbox.paypal.com/AdaptivePayments/Preapproval',
		headers: {
			'Content-Type': 'application/x-www-form-urlencoded',
			'X-PAYPAL-SECURITY-USERID': 'pavel.yankelevich-facilitator_api1.ncr.com',
			'X-PAYPAL-SECURITY-PASSWORD': 'U5WF37CSX9WSPCXP',
			'X-PAYPAL-SECURITY-SIGNATURE': 'AFcWxV21C7fd0v3bYYYRCpSSRl31A84oshmk-KxnmMfYmt3yw-ylVlcA',
			'X-PAYPAL-REQUEST-DATA-FORMAT': 'NV',
			'X-PAYPAL-RESPONSE-DATA-FORMAT': 'JSON',
			'X-PAYPAL-APPLICATION-ID': 'APP-80W284485P519543T'
		},
		body: {
			'returnUrl': 'http://www.yourdomain.com/success.html',
			'cancelUrl': 'http://www.yourdomain.com/cancel.html',
			'startingDate': now.format('YYYY-MM-DD'),
			'endingDate': futureDate.format('YYYY-MM-DD'),
			'currencyCode': 'USD',
			'requestEnvelope.errorLanguage': 'en_US',
			'pinType': 'REQUIRED'
		},
		success: function(httpResponse) {
			if (httpResponse.data["responseEnvelope"]["ack"] == "Success") {

				var paymentMethodQuery = new Parse.Query("PaymentMethod");
				paymentMethodQuery.equalTo("user", request.user);
				paymentMethodQuery.equalTo("type", 0); //PayPal
				paymentMethodQuery.first({
					success: function(paymentMethod) {
						if (paymentMethod == undefined) {
							var PaymentMethod = Parse.Object.extend("PaymentMethod");
							var paymentMethod = new PaymentMethod();

							paymentMethod.save({
								"user": request.user,
								"type": 0, //PayPal
								"connectionData": {
									preapprovalKey: httpResponse.data["preapprovalKey"],
									confirmed: false
								}
							}, {
								success: function(pm) {
									response.success(httpResponse.data);
								},

								error: function(error) {
									console.log("Failed to set Payment Method: " + error.message);
									response.error("Failed to set Payment Method: " + error.message);
								}
							});
						} else {
							paymentMethod.set("connectionData", {
								preapprovalKey: httpResponse.data["preapprovalKey"],
								confirmed: false
							});
							paymentMethod.save();
							response.success(httpResponse.data);
						}
					},
					error: function(error) {
						console.log("Failed to set Payment Method: " + error.message);
						response.error("Failed to set Payment Method: " + error.message);
					}
				});
			} else
				response.success(httpResponse.data);
		},
		error: function(httpResponse) {
			response.error('Request failed with response code ' + httpResponse.status);
		}
	});
});