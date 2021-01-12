from myaddons.SCM.models.connection import connect_send
from odoo import models, fields, api
import logging

_logger = logging.getLogger(__name__)
import requests
import json
import socket


class Query(models.Model):
    _name = "query.details"
    _description = "query details"

    transactionid = fields.Char('Transaction ID')

    def query(self):
        data = {
            'label': 'enroll',
            'transactionid': self.transactionid
        }

        _logger.info("Is this printing?")
        # connect_send(data)
