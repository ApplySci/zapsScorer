# -*- coding: utf-8 -*-
'''
The WTForms specification for forms generated on the server
'''

# framework imports

from flask_login import current_user
from flask_wtf import FlaskForm
from wtforms import BooleanField, PasswordField, StringField, SubmitField
from wtforms.fields.html5 import EmailField, TelField
from wtforms.validators import InputRequired, Email, EqualTo, Regexp, ValidationError

# app imports
from mjserver.models import Player

#%% --- fields

class MyEmailField(EmailField):
    @staticmethod
    def validate_email(form, email):
        user = Player.query.filter_by(email=email.data).first()
        if user is not None and user is not current_user:
            raise ValidationError('Email already in use. Please use a different one.')


#%% --- forms

class EmailForm(FlaskForm):
    email = StringField('Email', validators=[InputRequired(), Email()])
    submit = SubmitField('Please send me a password-reset link')


class LoginForm(FlaskForm):
    ''' login an existing user '''
    name = StringField('Name', validators=[InputRequired()], render_kw={'autofocus': True},)
    password = PasswordField('Password', validators=[InputRequired()])
    remember_me = BooleanField('Remember Me')
    submit = SubmitField('Sign In')


class PasswordForm(FlaskForm):
    ''' to reset the password '''
    password = PasswordField('Password', validators=[InputRequired()])
    password2 = PasswordField(
        'Repeat Password', validators=[InputRequired(), EqualTo('password')])
    submit = SubmitField('Register')


class ProfileForm(FlaskForm):
    ''' user can update their own details '''

    email = MyEmailField(
        validators = [InputRequired() , Email(), MyEmailField.validate_email],
        label = 'Your email',
        )

    token = StringField(
        'Device token (to tie a device to this account)',
        render_kw={'readonly': True},
        )

    _reg = '[0-9]{4}'
    pin = TelField(
        label = '4-digit PIN number',
        validators = [InputRequired(), Regexp(_reg, message='Must be 4 digits')],
        render_kw={
        'minlength': 4,
        'maxlength': 4,
        'pattern': _reg,
        'title': 'four digits'
        }
        )


class RegistrationForm(FlaskForm):
    ''' register a new user '''

    name = StringField('Name', validators=[InputRequired()])
    email = MyEmailField('Email')
    validate_email = MyEmailField.validate_email
    password = PasswordField('Password', validators=[InputRequired()])
    password2 = PasswordField(
        'Repeat Password', validators=[InputRequired(), EqualTo('password')])
    _reg = '[0-9]{4}'
    pin = TelField(
        label = '4-digit PIN number',
        validators = [InputRequired(), Regexp(_reg, message='Must be 4 digits')],
        render_kw={
        'minlength': 4,
        'maxlength': 4,
        'pattern': _reg,
        'title': 'four digits'
        }
        )
    submit = SubmitField('Register')

    def validate_name(self, name):
        user = Player.query.filter_by(name=name.data).first()
        if user is not None:
            raise ValidationError('Name already in use. Please use a different one.')
