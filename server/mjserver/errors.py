# -*- coding: utf-8 -*-
'''
error-handling for server problems. Pretty rudimentary so far
'''

# framework imports
from flask import jsonify, render_template
from werkzeug.http import HTTP_STATUS_CODES

# app imports
from mjserver import app, db

def bad_request(message):
    return error_response(400, message)

@app.errorhandler(404)
def not_found_error(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return render_template('500.html'), 500

def error_response(status_code, message=None):
    payload = {'error': HTTP_STATUS_CODES.get(status_code, 'Unknown error')}
    if message:
        payload['message'] = message
    response = jsonify(payload)
    response.status_code = status_code
    return response