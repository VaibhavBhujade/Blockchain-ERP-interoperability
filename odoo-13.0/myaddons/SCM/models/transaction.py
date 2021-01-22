from myaddons.SCM.models.connection import connect_send
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
        self.env.cr.execute("""SELECT enrollment_details.enrollmentid FROM public.enrollment_details""")
        enrollmentID = self.env.cr.fetchall()[0][0]

        # fetching org name from db
        self.env.cr.execute("""SELECT enrollment_details.org FROM public.enrollment_details""")
        orgname = self.env.cr.fetchall()[0][0]

        # fetch user id from db: NOTE: there are many users. for now fetch only first one.
        self.env.cr.execute("""SELECT register_details.userid FROM public.register_details""")
        userid = self.env.cr.fetchall()[0][0]

        data = {
            'label': 'query',
            'enrollmentID': enrollmentID,
            'org': orgname,
            'userid': userid
        }
        connect_send(data, 'query')
        _logger.info(data)

    def generate_sign(self):
        self.env.cr.execute("""SELECT enrollment_details.enrollmentid FROM public.enrollment_details""")
        enrollmentID = self.env.cr.fetchall()[0][0]

        # fetching org name from db
        self.env.cr.execute("""SELECT enrollment_details.org FROM public.enrollment_details""")
        orgname = self.env.cr.fetchall()[0][0]

        # fetch user id from db: NOTE: there are many users. for now fetch only first one.
        self.env.cr.execute("""SELECT register_details.userid FROM public.register_details""")
        userid = self.env.cr.fetchall()[0][0]

        data = {
            'label': 'generate',
            'enrollmentID': enrollmentID,
            'org': orgname,
            'userid': userid,
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
        connect_send(data, 'generateSign')
        _logger.info(data)

    def send_to_ledger(self):
        # fetching org name from db
        self.env.cr.execute("""SELECT enrollment_details.org FROM public.enrollment_details""")
        orgname = self.env.cr.fetchall()[0][0]

        # fetch user id from db: NOTE: there are many users. for now fetch only first one.
        self.env.cr.execute("""SELECT register_details.userid FROM public.register_details""")
        userid = self.env.cr.fetchall()[0][0]

        data = {'label': 'transaction',
                'org': orgname,
                'userid': userid,
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

        connect_send(data, 'transaction')
        self.env.user.notify_success("Transaction Successful")
