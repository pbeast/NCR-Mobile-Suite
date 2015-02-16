
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

var failureResponce = function(messageText){
	return {status : 0, message : messageText};
}

var successResponce = function(messageText, responseData){
	return {status : 1, message : messageText, data : responseData };
}


Parse.Cloud.define("createAssociation", function(request, response) {

	if (request.params.installationId == undefined) {
		response.error(failureResponce("installationId is mandatory parameter"));
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
							response.success(successResponce("OK", sequenceObject.get("sequence")));
						},
						error: function(association, error) {
							response.error(failureResponce('Failed to create new object, with error: ' + error.message));
						}
					});
				},
				error: function(error) {
					console.log(error);
					response.error(failureResponce('Failed to save counter, with error: ' + error.message));
				}
			});
		},
		error: function(error) {
			console.log(error);
			response.error(failureResponce('Failed to retrieve counter, with error: ' + error.message));
		}
	});
});

var createReceiptAndSendPush = function(response, association, receiptText, total, storeAddress, retailer) {
	var Receipts = Parse.Object.extend("Receipts");
	var receipt = new Receipts();

	var installationId = association.get("installationId");

	receipt.save({
		"installationId": installationId,
		"user": association.get("user"),
		"receipt": receiptText,
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
					response.success(successResponce("Receipt published successfully; Push was successful", null));
				},
				error: function(error) {
					console.log("Push was unsuccessful: " + error.message);
					response.success(
					{
						status : 2,
						message : "Receipt published successfully; Push was unsuccessful: " + error.message,
						data : null
					});
				}
			});
		},
		error: function(receipt, error) {
			response.error(failureResponce('Failed to create new receipt, with error code: ' + error.message));
		}
	});
}

Parse.Cloud.define("publishReceipt", function(request, response) {
	if (request.params.syncCode == undefined) {
		response.error(failureResponce("pinCode is mandatory parameter"));
		return;
	}

	if (request.params.receipt == undefined) {
		response.error(failureResponce("receipt is mandatory parameter"));
		return;
	}

	if (request.params.total == undefined) {
		response.error(failureResponce("total is mandatory parameter"));
		return;
	}

	if (request.params.retailerId == undefined) {
		response.error(failureResponce("retailerId is mandatory parameter"));
		return;
	}

	if (request.params.storeAddress == undefined) {
		response.error(failureResponce("storeAddress is mandatory parameter"));
		return;
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
					response.error(failureResponce("Failed to find association. Error=" + error.message));
				}
			});
		},
		error: function() {
			response.error(failureResponce("Retailer not found. Error=" + error.message));
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

			response.success(successResponce("success", null));
		},
		error: function(error) {
			response.error(failureResponce("installation lookup failed:" + error.message));
		}
	});
});

Parse.Cloud.define("associateInstallationWithUser", function(request, response) {
	if (request.params.installationId == undefined) {
		response.error(failureResponce("installationId is mandatory parameter"));
		return
	}

	if (request.user == undefined) {
		response.error(failureResponce("no logged-in user"));
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
					response.success(successResponce("OK", null));
				},
				function(error) {
					response.error(failureResponce("receipts lookup failed:" + error.message));
				});
		},
		error: function(error) {
			response.error(failureResponce("receipts lookup failed:" + error.message));
		}
	});
});

Parse.Cloud.define("fetchReceipts", function(request, response) {
	console.log(request.user);
	console.log(request.params.lastFetchTime);


	var receiptsQuery = new Parse.Query("Receipts");
	if (request.params.lastFetchTime != "" && request.params.lastFetchTime != undefined)
		receiptsQuery.greaterThan("createdAt", request.params.lastFetchTime);

	if (request.user == undefined) {
		receiptsQuery.equalTo("installationId", request.params.installationId);
		receiptsQuery.equalTo("user", null);
		console.log('will search by installationId');
	}
	else{
		receiptsQuery.equalTo('user', request.user);
		console.log('will search by user');
	}

	receiptsQuery.include("retailer");
	receiptsQuery.descending("createdAt");

	receiptsQuery.find({
		success: function(results) {
			if (results.length == 0) {
				response.success(successResponce("No receipts found for user", []));
				return;
			}

			response.success(successResponce("found " + results.length + " receipts", results));
		},
		error: function(error) {
			response.error(failureResponce("receipts lookup failed:" + error.message));
		}
	});
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
				response.error(failureResponce("Payment method not found"));
			} else {
				var connectionData = paymentMethod.get("connectionData");
				connectionData["confirmed"] = true;

				paymentMethod.set("connectionData", connectionData);
				paymentMethod.save();
				response.success(successResponce("", null));
			}
		},
		error: function(error) {
			console.log("Failed to update Payment Method: " + error.message);
			response.error(failureResponce("Failed to update Payment Method: " + error.message));
		}
	});
});

Parse.Cloud.define("removePayPalConnection", function(request, response) {

	if (request.user == undefined) {
		response.error("You have to login first");
		return
	}
	var paymentMethodQuery = new Parse.Query("PaymentMethod");
	paymentMethodQuery.equalTo("user", request.user);
	paymentMethodQuery.equalTo("type", 0); //PayPal
	paymentMethodQuery.first({
		success: function(paymentMethod) {
			paymentMethod.destroy();
			response.success(successResponce("PayPal connection removed", null));
		},
		error: function(error) {
			console.log("Failed to update Payment Method: " + error.message);
			response.error(failureResponce("Failed to update Payment Method: " + error.message));
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
									response.success(successResponce("Preapproval retrieved successfully", httpResponse.data));
								},

								error: function(error) {
									console.log("Failed to set Payment Method: " + error.message);
									response.error(failureResponce("Failed to set Payment Method: " + error.message));
								}
							});
						} else {
							paymentMethod.set("connectionData", {
								preapprovalKey: httpResponse.data["preapprovalKey"],
								confirmed: false
							});
							paymentMethod.save();
							response.success(successResponce("Preapproval retrieved successfully", httpResponse.data));
						}
					},
					error: function(error) {
						console.log("Failed to set Payment Method: " + error.message);
						response.error(failureResponce("Failed to set Payment Method: " + error.message));
					}
				});
			} else
				response.success(successResponce("Preapproval retrieved successfully", httpResponse.data));
		},
		error: function(httpResponse) {
			response.error(failureResponce('Request failed with response code ' + httpResponse.status))	;
		}
	});
});


Parse.Cloud.define("requestPayment", function(request, response) {
	if (request.params.syncCode == undefined) {
		response.error(failureResponce("pinCode is mandatory parameter"));
		return;
	}
	
	if (request.params.total == undefined) {
		response.error(failureResponce("total is mandatory parameter"));
		return;
	}

	if (request.params.currencySymbol == undefined) {
		response.error(failureResponce("currencySymbol is mandatory parameter"));
		return;
	}

	if (request.params.retailerId == undefined) {
		response.error(failureResponce("retailerId is mandatory parameter"));
		return;
	}

	if (request.params.storeAddress == undefined) {
		response.error(failureResponce("storeAddress is mandatory parameter"));
		return;
	}

	if (request.params.callBackUrl == undefined) {
		response.error(failureResponce("callBackUrl is mandatory parameter"));
		return;
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

					var r = createPaymentAndSendPush(
						response,
						association,
						request.params.currencySymbol,
						request.params.total,
						request.params.storeAddress,
						retailer,
						request.params.callBackUrl
					);
				},
				error: function(error) {
					response.error(failureResponce("Failed to find association. Error=" + error.message));
				}
			});
		},
		error: function() {
			response.error(failureResponce("Retailer not found. Error=" + error.message));
		}
	});
});

var createPaymentAndSendPush = function(response, association, currencySymbol, total, storeAddress, retailer, callBackUrl) {
	var Payment = Parse.Object.extend("Payment");
	var payment = new Payment();

	var installationId = association.get("installationId");

	payment.save({
		"installationId": installationId,
		"user": association.get("user"),
		"currencySymbol": currencySymbol,
		"total": total,
		"storeAddress": storeAddress,
		"retailer": retailer,
		"callBackUrl":callBackUrl,
		"status":1  //creataed
	}, {
		success: function(payment) {
			console.log("Payment stored successful");

		//	association.destroy();

			var query = new Parse.Query(Parse.Installation);
			query.equalTo('installationId', installationId);
			Parse.Push.send({
				where: query,
				data: {
					alert: "New Payment is ready",
					title: "NCR Mobile Suite",
					badge: "1",
					pushReason: 1 //New Payment
				}
			}, {
				success: function() {
					console.log("Push  for payment was successful");
					response.success(successResponce("Payment created successfully; Push was successful", null));
				},
				error: function(error) {
					console.log("Push for payment was unsuccessful: " + error.message);
					response.success(
					{
						status : 2,
						message : "Payment published successfully; Push was unsuccessful: " + error.message,
						data : null
					});
				}
			});
		},
		error: function(receipt, error) {
			response.error(failureResponce('Failed to create new receipt, with error code: ' + error.message));
		}
	});
}