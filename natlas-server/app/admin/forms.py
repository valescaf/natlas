from flask_wtf import FlaskForm
from wtforms import StringField, BooleanField, SubmitField, TextAreaField
from wtforms.validators import DataRequired, ValidationError, Email
from app.models import User, ScopeItem
import ipaddress

class InviteUserForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    submit = SubmitField('Invite User')

    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if user is not None:
            raise ValidationError('Email %s already exists!' % user.email)


class UserDeleteForm(FlaskForm):
    deleteUser = SubmitField('Delete User')


class UserEditForm(FlaskForm):
    editUser = SubmitField('Toggle Admin')


class NewScopeForm(FlaskForm):
    target = StringField('Target', validators=[DataRequired()])
    blacklist = BooleanField('Blacklist')
    submit = SubmitField('Add Target')

    def validate_target(self, target):
        item = ScopeItem.query.filter_by(target=target.data).first()
        if item is not None:
            raise ValidationError('Target %s already exists!' % item.target)
        try:
            isValid = ipaddress.IPv4Interface(target.data)
        except ipaddress.AddressValueError:
            raise ValidationError(
                'Target %s couldn\'t be validated' % target.data)


class ImportScopeForm(FlaskForm):
    scope = TextAreaField("Scope Import")
    submit = SubmitField("Import Scope")

    def validate_scope(self, scope):
        for target in scope.data.split('\n'):
            target = target.strip()
            if '/' not in target:
                target = target + '/32'
            try:
                isValid = ipaddress.IPv4Network(target)
            except ipaddress.AddressValueError:
                raise ValidationError(
                    'Target %s couldn\'t be validated' % target)


class ScopeDeleteForm(FlaskForm):
    deleteScopeItem = SubmitField('Delete Target')


class ScopeToggleForm(FlaskForm):
    toggleScopeItem = SubmitField('Toggle Blacklist')