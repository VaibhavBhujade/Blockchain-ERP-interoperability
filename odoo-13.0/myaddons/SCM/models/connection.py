import socket
from json import JSONEncoder
import datetime
import logging
import sys
import json


class DisplayHelper:
    __instance = None
    data = None
    trace = None

    @staticmethod
    def getInstance():
        """ Static access method. """
        if DisplayHelper.__instance is None:
            print("First time called")
            DisplayHelper()
        return DisplayHelper.__instance

    def __init__(self):
        """ Virtually private constructor. """
        if DisplayHelper.__instance is not None:
            raise Exception("This class is a singleton!")
        else:
            DisplayHelper.__instance = self

    def display(self, information, flag):
        if flag == 'query':
            print("Information: " + information)
            transaction_list = information.split('}')
            DisplayHelper.data = transaction_list
            print("data", DisplayHelper.data)
            print("Type", type(DisplayHelper.data))
        elif flag == 'trace':
            traced_list = information.split('}')
            DisplayHelper.trace = traced_list
            print("Traced Result", DisplayHelper.trace)
            print("Type", type(DisplayHelper.trace))

    def getData(self):
        return DisplayHelper.data

    def getTracedResults(self):
        return DisplayHelper.trace


_logger = logging.getLogger(__name__)


class DateTimeEncoder(JSONEncoder):
    # Override the default method
    def default(self, obj):
        if isinstance(obj, (datetime.date, datetime.datetime)):
            return obj.isoformat()


def connect_send(data, flag):
    _logger.info('CONNECTION SUCCESSFUL')
    _logger.info(data)
    # TCP
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_address = ('localhost', 10000)
    print(server_address)
    sock.connect(server_address)

    try:
        # Send data
        message = data
        print(sys.stderr, 'sending "%s"' % message)
        s = json.dumps(data, indent=4, cls=DateTimeEncoder)
        print(s)
        sock.sendall(bytes(s, encoding="utf-8"))

    finally:
        information = str(sock.recv(1024), 'utf-8')
        print(information)
        if flag == 'query':
            displayHelper = DisplayHelper.getInstance()
            displayHelper.display(information, 'query')
            print("Printed the information")
            displayHelper.getData()
        elif flag == 'trace':
            displayHelper = DisplayHelper.getInstance()
            displayHelper.display(information, 'trace')
            print("Printed the information")
            displayHelper.getData()

        print(sys.stderr, 'closing socket')
        sock.close()
    # END ####
