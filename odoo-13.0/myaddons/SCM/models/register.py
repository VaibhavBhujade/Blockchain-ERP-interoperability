from myaddons.SCM.models.connection import connect_send
from odoo import models, fields

import logging

_logger = logging.getLogger(__name__)


class Register(models.Model):
    _name = "register.details"
    _description = "register details"

    userid = fields.Char('User ID')
    enrollmentid = fields.Char('Enrollment ID')
    org = fields.Char('Organisation')

    def register_user(self):
        data = {
            'label': 'register',
            'enrollmentID': self.enrollmentid,
            'userID': self.userid,
            'org': self.org,
        }
        connect_send(data)
        self.env.user.notify_success(self.userid + " from " + self.org + " has been enrolled successfully")
