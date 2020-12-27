from odoo import models, fields, api

import logging

_logger = logging.getLogger(__name__)
import requests
import json
import socket
import sys
import datetime
from json import JSONEncoder

class DateTimeEncoder(JSONEncoder):
    # Override the default method
    def default(self, obj):
        if isinstance(obj, (datetime.date, datetime.datetime)):
            return obj.isoformat()


class TransactionDetails(models.Model):
    _name = 'transaction.details'
    _description = 'transaction details'

    transactionID = fields.Char('Transaction ID')
    product_name = fields.Char('Product Name')
    product_code = fields.Char('Product Code')
    # batch_ID = fields.Char('Batch ID')
    quantity = fields.Float('Quantity')
    quantity_unit = fields.Char('Unit')
    price = fields.Float('Price')
    expected_delivery = fields.Date('Expected Delivery')
    promise_delivery = fields.Date('Promise Delivery')
    eid_buyer = fields.Char('EID Buyer')
    eid_seller = fields.Char('EID Seller')
    prev_transactions = fields.Char('Prev transaction ids')
    amount = fields.Float(string='Final amount (inc GST and delivery charges)')
    other_details = fields.Binary('Add other ERP specific files')

    def query_ledger(self):
        _logger.info('CONNECTION SUCCESSFUL')
        data = {
            'label': 'query'
        }
        _logger.info(data)
        _logger.info(self._name)
        #### TCP ####
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_address = ('localhost', 10000)

        sock.connect(server_address)

        try:

            # Send data
            message = data
            print(sys.stderr, 'sending "%s"' % message)
            s = json.dumps(data, indent=4, cls=DateTimeEncoder)
            print("sendddddddd")
            sock.sendall(bytes(s, encoding="utf-8"))
            print("sent")



        finally:
            print(sys.stderr, 'closing socket')
            sock.close()
        #### END ####

    def send_to_ledger(self):
        _logger.info('CONNECTION SUCCESSFUL')
        data = {'label': 'transaction',
                'transactionID': self.transactionID,
                'product_name': self.product_name,
                'product_code': self.product_code,
                'quantity': self.quantity,
                'quantity_unit': self.quantity_unit,
                'price': self.price,
                'expected_delivery': self.expected_delivery,
                'promise_delivery': self.promise_delivery,
                'eid_buyer': self.eid_buyer,
                'eid_seller': self.eid_seller,
                'prev_transactions': self.prev_transactions,
                'amount': self.amount
                }
        _logger.info(data)
        _logger.info(self._name)
        #### TCP ####
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_address = ('localhost', 10000)

        sock.connect(server_address)

        try:

            # Send data
            message = data
            print(sys.stderr, 'sending "%s"' % message)
            s = json.dumps(data, indent=4, cls=DateTimeEncoder)
            print("sendddddddd")
            sock.sendall(bytes(s,encoding="utf-8"))
            print("sent")



        finally:
            print(sys.stderr, 'closing socket')
            sock.close()
        #### END ####

        _logger.info('helloagain')
        # data = json.loads(request.httprequest.data)
