from myaddons.SCM.models.connection import connect_send
from odoo import models, fields, api

import logging

_logger = logging.getLogger(__name__)
import requests
import json
import socket


class Enrollment(models.Model):
    _name = "enrollment.details"
    _description = "enrollment details"

    enrollmentid = fields.Char('Enrollment ID')
    enrollmentsecret = fields.Char('Enrollment Secret')
    org = fields.Char('Organisation')

    def enroll_admin(self):
        data = {
            'label': 'enroll',
            'enrollmentID': self.enrollmentid,
            'enrollmentSecret': self.enrollmentsecret,
            'org': self.org,
        }
        connect_send(data, 'enroll')
        self.env.user.notify_success("Admin has been enrolled successfully")
