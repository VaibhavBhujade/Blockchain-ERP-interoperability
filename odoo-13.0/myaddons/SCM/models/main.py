from odoo import http
from odoo.http import request


from myaddons.SCM.models.connection import DisplayHelper


class Display(http.Controller):

    @http.route('/querytx/', website=True, auth='public')
    def ledger_results(self, **kw):
        # return 'HelloWorld'
        print("dataissssss")
        # print(data)
        displayhelper = DisplayHelper.getInstance()
        data = displayhelper.getData()
        print(data)
        return request.render("SCM.transacts", {
            'transactions': data
        })
