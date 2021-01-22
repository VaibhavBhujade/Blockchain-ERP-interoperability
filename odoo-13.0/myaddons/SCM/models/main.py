from odoo import http
from odoo.http import request

data = {}


def display(information):
    print("Display Function called")
    print("Information: " + information)
    global data
    data = information
    print("data" + data)


class Display(http.Controller):

    @http.route('/query/', website=True, auth='public')
    def ledger_results(self, **kw):
        # return 'HelloWorld'
        print("dataissssss")
        print(data)
        return request.render("SCM.transacts", {
            'fake': 1,
            'transactions': data
        })
