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
        self.env.cr.execute("""SELECT enrollment_details.enrollmentid FROM public.enrollment_details""")
        enrollmentID = self.env.cr.fetchall()[0][0]

        # fetching org name from db
        self.env.cr.execute("""SELECT enrollment_details.org FROM public.enrollment_details""")
        orgname = self.env.cr.fetchall()[0][0]

        # fetch user id from db: NOTE: there are many users. for now fetch only first one.
        self.env.cr.execute("""SELECT register_details.userid FROM public.register_details""")
        userid = self.env.cr.fetchall()[0][0]
        data = {
            'label': 'trace',
            'enrollmentID': enrollmentID,
            'org': orgname,
            'userid': userid,
            'tx_id': self.transactionid
        }

        _logger.info("Is this printing?")
        connect_send(data, 'trace')
        return {
            "url": "/tracetx/",
            "type": "ir.actions.act_url"
        }

