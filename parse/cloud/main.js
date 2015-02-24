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

var failureResponce = function(messageText) {
	return {
		status: 0,
		message: messageText
	};
}

var successResponce = function(messageText, responseData) {
	return {
		status: 1,
		message: messageText,
		data: responseData
	};
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
					response.success({
						status: 2,
						message: "Receipt published successfully; Push was unsuccessful: " + error.message,
						data: null
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
		response.error(failureResponce("installationId is mandatory parameter"));
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
	} else {
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
		response.error(failureResponce("You have to login first"));
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
		response.error(failureResponce("You have to login first"));
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
		response.error(failureResponce("You have to login first"));
		return
	}

	//console.log(request);

	var now = moment(request.params.startDate);
	var futureDate = moment(request.params.startDate).add('y', 1);

	//console.log("Key will be valid from " + now.format('YYYY-MM-DD') + " to " + futureDate.format('YYYY-MM-DD'));

	Parse.Cloud.httpRequest({
		method: 'POST',
		url: 'https://svcs.sandbox.paypal.com/AdaptivePayments/Preapproval',
		headers: {
			'Content-Type': 'application/x-www-form-urlencoded',
			'X-PAYPAL-SECURITY-USERID': 'py250015-facilitator_api1.ncr.com',
			'X-PAYPAL-SECURITY-PASSWORD': '4D3V7GLHR6YWVH5R',
			'X-PAYPAL-SECURITY-SIGNATURE': 'AFcWxV21C7fd0v3bYYYRCpSSRl31AcdPEIBTurps3J6Wv8U830dyq4W0',
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

								error: function(httpResponse) {
									console.log("Failed to set Payment Method: " + httpResponse);
									response.error(failureResponce("Failed to set Payment Method: " + httpResponse.status));
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
			response.error(failureResponce('Request failed with response code ' + httpResponse.status));
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

	if (request.params.posTransactionId == undefined) {
		response.error(failureResponce("posTransactionId is mandatory parameter"));
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
						request.params.callBackUrl,
						request.params.posTransactionId
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

var createPaymentAndSendPush = function(response, association, currencySymbol, total, storeAddress, retailer, callBackUrl, posTransactionId) {
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
		"callBackUrl": callBackUrl,
		"posTransactionId" : posTransactionId,
		"status": 0 //creataed
	}, {
		success: function(updatedPayment) {
			console.log("Payment stored successful");
			
			console.log(updatedPayment);
			var paymentIdValue = updatedPayment.id;
			console.log("paymentId = " + paymentIdValue);

			var query = new Parse.Query(Parse.Installation);
			query.equalTo('installationId', installationId);
			Parse.Push.send({
				where: query,
				data: {
					alert: "Payment Requested",
					title: "NCR Mobile Suite",
					pushReason: 1, //New Payment
					paymentId: paymentIdValue
				}
			}, {
				success: function() {
					console.log("Push  for payment was successful");
					response.success(successResponce("Payment created successfully; Push was successful", {
						paymentId: paymentIdValue,
						"posTransactionId" : posTransactionId
					}));
				},
				error: function(error) {
					console.log("Push for payment was unsuccessful: " + error.message);
					response.success({
						status: 2,
						message: "Payment published successfully; Push was unsuccessful: " + error.message,
						data: {
							paymentId: paymentIdValue
						}
					});
				}
			});
		},
		error: function(receipt, error) {
			response.error(failureResponce('Failed to create new payment, with error code: ' + error.message));
		}
	});
}


Parse.Cloud.define("getPaymentById", function(request, response) {
	if (request.user == undefined) {
		response.error(failureResponce("You have to login first"));
		return
	}

	if (request.params.paymentId == undefined) {
		response.error(failureResponce("No Payment Id"));
		return
	}

	var Payment = Parse.Object.extend("Payment");
	var paymentQuery = new Parse.Query(Payment);
	paymentQuery.include("retailer");
	paymentQuery.include("user");

	paymentQuery.get(request.params.paymentId, {
		success: function(payment) {
			if (payment.get('status') != 0) {
				response.error(failureResponce('Requested payment has incorrect status ' + payment.get('status')));
				return;
			}

			if (payment.get('user').id != request.user.id) {
				response.error(failureResponce('Wrong user!!!'));
				return;
			}

			response.success(successResponce("Payment found", {
				retailerName: payment.get('retailer').get('name'),
				logo: payment.get('retailer').get('logo'),
				storeAddress: payment.get('storeAddress'),
				total: payment.get('total'),
				currencySymbol: payment.get('currencySymbol')
			}));
		},
		error: function(object, error) {
			console.log(error);
			response.error(failureResponce('Failed to retrieve payment data, with error: ' + error.message));
		}
	});
});

Parse.Cloud.define("rejectPayment", function(request, response) {
	if (request.user == undefined) {
		response.error(failureResponce("You have to login first"));
		return
	}

	if (request.params.paymentId == undefined) {
		response.error(failureResponce("No Payment Id"));
		return
	}

	var Payment = Parse.Object.extend("Payment");
	var paymentQuery = new Parse.Query(Payment);
	paymentQuery.include("user");

	paymentQuery.get(request.params.paymentId, {
		success: function(payment) {
			if (payment.get('status') != 0) {
				response.error(failureResponce('Requested payment has incorrect status ' + payment.get('status')));
				return;
			}

			if (payment.get('user').id != request.user.id) {
				response.error(failureResponce('Wrong user!!!'));
				return;
			}

			payment.save({
				'status': 2 //Rejected
			}, {
				success: function(updatedPayment) {
					Parse.Cloud.httpRequest({
						method: 'POST',
						url: payment.get('callBackUrl') + "/rejected",
						body: {},
						success: function(httpResponse) {
							response.success(successResponce('Payment rejected', httpResponse.data));
						},
						error: function(error) {
							console.log("Failed to update POS: " + error.message);
							response.error(failureResponce("Payment rejected, but failed to update POS: " + error));
						}
					});

				},
				error: function(error) {
					response.error(failureResponce("Failed to reject payment: " + error));
				}
			});
		},
		error: function(error) {

		}
	});
});


//http://address:port/storeId/posId/result/resultData
//result:
//	success; resultData = {provider: *PayPal*, payPalApproval: payPalApprovalKey, paymentId : xxx}
//	providerAccessError
//	providerError; resultData = {provider: '*PayPal*', errorDescription : 'xxxx'}
//	rejectedByUser

var updatePaymentAndPos = function(payment, status, providerResponseData, posMessage) {
	payment.save({
		'status': status,
		'providerResponseData': providerResponseData,
		'processedUsing': 'PayPal'
	}, {
		success: function(updatedPayment) {
			Parse.Cloud.httpRequest({
				method: 'POST',
				url: payment.get('callBackUrl') + "/" + posMessage,
				body: {},
				success: function(httpResponse) {
					response.success(providerResponseData);
				},
				error: function(error) {
					console.log("Failed to update POS: " + error.message);
					response.error(failureResponce("Payment is done, but failed to update POS: " + error));
				}
			});
		},
		error: function(error) {
			response.error(failureResponce('Requested payment is incorrect status ' + error.message));
		}
	});
};

Parse.Cloud.define("payWithPayPal", function(request, response) {
	if (request.user == undefined) {
		response.error(failureResponce("You have to login first"));
		return
	}

	if (request.params.paymentId == undefined) {
		response.error(failureResponce("No Payment Id"));
		return
	}

	if (request.params.pinCode == undefined) {
		response.error(failureResponce("PayPal pinCode is required"));
		return
	}

	var Payment = Parse.Object.extend("Payment");
	var paymentQuery = new Parse.Query(Payment);
	paymentQuery.include("user");
	paymentQuery.include("retailer");

	paymentQuery.get(request.params.paymentId, {
		success: function(payment) {
			if (payment.get('status') != 0) {
				response.error(failureResponce('Requested payment has incorrect status ' + payment.get('status')));
				return;
			}

			if (payment.get('user').id != request.user.id) {
				response.error(failureResponce('Wrong user!!!'));
				return;
			}

			var paymentMethodQuery = new Parse.Query("PaymentMethod");
			paymentMethodQuery.equalTo("user", request.user);
			paymentMethodQuery.equalTo("type", 0); //PayPal
			paymentMethodQuery.first({
				success: function(paymentMethod) {
					var connectionData = paymentMethod.get("connectionData");
					if (connectionData["confirmed"] == false) {
						response.error("Can't proceed with the payment. PayPal connection not completed");
						return;
					}

					/*
											var payPalPayment = {
												actionType: "PAY",
												currencyCode: "USD",
												feesPayer : "EACHRECEIVER",
												// "receiverList.receiver(0).amount" : payment.get("total"),
												// "receiverList.receiver(0).email" : "merchant@ncr.com",
												 receiverList: {
												 	receiver: [{
												 		amount: payment.get("total"),
												 		email: "merchant@ncr.com"
												 	}]
												 },
												returnUrl: "http://Payment-Success-URL",
												cancelUrl: "http://Payment-Cancel-URL",
												requestEnvelope: {
													errorLanguage: "en_US",
													detailLevel: "ReturnAll"
												},
												pinCode: request.params.pinCode,
												preapprovalKey : connectionData['preapprovalKey']
											};
					*/

					var payPalPayment = "actionType=PAY&currencyCode=USD&feesPayer=EACHRECEIVER" +
						"&receiverList.receiver(0).amount=" + payment.get("total") +
						"&receiverList.receiver(0).email=" + encodeURIComponent(payment.get('retailer').get('payPalAccount')) +
						"&returnUrl=" + encodeURIComponent("http://Payment-Success-URL") +
						"&cancelUrl=" + encodeURIComponent("http://Payment-Cancel-URL") +
						"&requestEnvelope.errorLanguage=en_US" +
						"&pin=" + request.params.pinCode +
						"&preapprovalKey=" + encodeURIComponent(connectionData['preapprovalKey']);

					Parse.Cloud.httpRequest({
						method: 'POST',
						url: 'https://svcs.sandbox.paypal.com/AdaptivePayments/Pay',
						headers: {
							'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
							'X-PAYPAL-SECURITY-USERID': 'py250015-facilitator_api1.ncr.com',
							'X-PAYPAL-SECURITY-PASSWORD': '4D3V7GLHR6YWVH5R',
							'X-PAYPAL-SECURITY-SIGNATURE': 'AFcWxV21C7fd0v3bYYYRCpSSRl31AcdPEIBTurps3J6Wv8U830dyq4W0',
							'X-PAYPAL-REQUEST-DATA-FORMAT': 'NV',
							'X-PAYPAL-RESPONSE-DATA-FORMAT': 'JSON',
							'X-PAYPAL-APPLICATION-ID': 'APP-80W284485P519543T'
						},
						body: payPalPayment,
						success: function(httpResponse) {

							var providerResponseData = httpResponse.data;
							if (providerResponseData['responseEnvelope']['ack'] == 'Success') {
								console.log("Payment succeeded");

								payment.save({
									'status': 1, //Paied
									'providerResponseData': providerResponseData,
									'processedUsing': 'PayPal'
								}, {
									success: function(updatedPayment) {
										var posResponseData = {
											"paymentId" : payment.id,
											"posTransactionId" : payment.get('posTransactionId'),
											"approvalReference" : providerResponseData['payKey'],
											"processedUsing" : "PayPal"
										};
										Parse.Cloud.httpRequest({
											method: 'POST',
											url: payment.get('callBackUrl') + "/success/" + encodeURIComponent(JSON.stringify(posResponseData)),
											body: {},
											success: function(httpResponse) {
												response.success(providerResponseData);
											},
											error: function(error) {
												console.log("Failed to update POS: " + error.message);
												response.error(failureResponce("Payment is done, but failed to update POS: " + error));
											}
										});
									},
									error: function(error) {
										response.error(failureResponce('Requested payment is incorrect status ' + error.message));
									}
								});
							}
						},
						error: function(httpResponse) {
							console.log(httpResponse);
							updatePaymentAndPos(payment, 3, null, "payPalFailure")
							response.error(failureResponce("Failed to process payment: (" + httpResponse.status + ") " + httpResponse.text));
						}
					});
				},
				error: function(error) {
					response.error(failureResponce("Failed to find PayPal connection. Error: " + error.message));
				}
			});
		},
		error: function(error) {
			console.log(error);
			response.error(failureResponce('Failed to retrieve payment data, with error: ' + error.message));
		}
	});
});