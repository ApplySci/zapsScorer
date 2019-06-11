# -*- coding: utf-8 -*-
'''
The WTForms specification for forms generated on the server
'''

# framework imports

from flask_login import current_user
from flask_wtf import FlaskForm
from wtforms import BooleanField, PasswordField, StringField, SubmitField
from wtforms.fields.html5 import EmailField, IntegerField
from wtforms.validators import DataRequired, Email, EqualTo, NumberRange, ValidationError

# app imports

from mjserver.models import User, load_user

#%% --- fields

class MyEmailField(EmailField):
    label = 'Email'
    validators = [DataRequired() , Email()]

    @staticmethod
    def validate_email(form, email):
        user = User.query.filter_by(email=email.data).first()
        if user is not None and user is not current_user:
            raise ValidationError('Email already in use. Please use a different one.')


class MyPinField(IntegerField):
    label = '4-digit PIN number that you will use to register games in the app',
    validators = [DataRequired(), NumberRange(min=1111, max=9999)]


#%% --- forms

class EmailForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    submit = SubmitField('Please send me a password-reset link')


class LoginForm(FlaskForm):
    ''' login an existing user '''
    name = StringField('Name', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    remember_me = BooleanField('Remember Me')
    submit = SubmitField('Sign In')


class PasswordForm(FlaskForm):
    ''' to reset the password '''
    password = PasswordField('Password', validators=[DataRequired()])
    password2 = PasswordField(
        'Repeat Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register')


class ProfileForm(FlaskForm):
    ''' user can update their own details '''

    email = MyEmailField()
    token = StringField('Device token (to tie a device to this account)', render_kw={'readonly': True})
    pin = MyPinField()
    submit = SubmitField('update-user')


class RegistrationForm(FlaskForm):
    ''' register a new user '''

    name = StringField('Name', validators=[DataRequired()])
    email = MyEmailField('Email')
    validate_email = MyEmailField.validate_email
    password = PasswordField('Password', validators=[DataRequired()])
    password2 = PasswordField(
        'Repeat Password', validators=[DataRequired(), EqualTo('password')])
    pin = MyPinField()
    submit = SubmitField('Register')

    def validate_name(self, name):
        user = User.query.filter_by(name=name.data).first()
        if user is not None:
            raise ValidationError('Name already in use. Please use a different one.')
