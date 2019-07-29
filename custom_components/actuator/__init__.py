import json
import requests
import os,re,random,string
import time
import base64
import hass_frontend
from urllib import parse
from threading import Thread,Event
import voluptuous as vol
import homeassistant.helpers.config_validation as cv

import logging
_LOGGER = logging.getLogger(__name__)


DOMAIN = 'actuator'

ACTUATE_SCHEMA = vol.Schema({
    vol.Required('sensor_id'): cv.string,
    vol.Optional('sensor_attr'): cv.string,
    vol.Required('sensor_values'): list,
    vol.Required('entity_id'): cv.string,
    vol.Optional('entity_attr'): cv.string,
    vol.Required('service'): cv.string,
    vol.Optional('service_attr'): cv.string,
    vol.Required('values'): list,
})

_hass = None

def setup(hass, config):
    global _hass
    _hass = hass
    hass.services.register(DOMAIN, 'actuate', actuate, schema=ACTUATE_SCHEMA)
    return True

def actuate(call):
    return
    sensor_id = call.data.get('sensor_id')
    sensor_attr = call.data.get('sensor_attr')
    sensor_values = call.data.get('sensor_values')

    entity_id = call.data.get('entity_id')
    entity_attr = call.data.get('entity_attr')
    service = call.data.get('service')
    service_attr = call.data.get('service_attr')
    values = call.data.get('values')
    domain = entity_id[:entity_id.find('.')]

    _LOGGER.error("%s, sensor_id: %s, sensor_attr: %s, sensor_values: %s", call, sensor_id, sensor_attr, sensor_values)
    _LOGGER.error("%s, entity_id: %s, entity_attr: %s, service: %s, service_attr: %s, values: %s", call.data, entity_id, entity_attr, service, service_attr, values)

    sensor_state = _hass.states.get(sensor_id)
    sensor_value = float(sensor_state.state if sensor_attr is None else sensor_state.attributes.get(sensor_attr))
    _LOGGER.error("sensor_id: %s, sensor_value: %s", sensor_id, sensor_value)

    state = _hass.states.get(sensor_id)
    state_value = state.state

    i = len(sensor_values) - 1
    while i >= 0:
        if sensor_value >= sensor_values[i]:
            value = values[i]
            entity_value = state_value if entity_attr is None else state.attributes.get(entity_attr)
            if entity_value == value:
                _LOGGER.debug('%s(%s)=%s not changed', entity_id, entity_attr, entity_value)
                return

            data = {'entity_id': entity_id, service_attr or entity_attr: value}
            _LOGGER.debug('%s(%s)=%s > %s\n  %s %s', entity_id, entity_attr, entity_value, value, service, data)
            with AsyncTrackStates(_hass) as changed_states:
                return await _hass.services.async_call(domain, service, data, True)
            return
        else:
            i = i - 1

    if state_value == 'off':
        _LOGGER.debug('%s(%s)=%s is already off', entity_id, entity_attr, entity_value)
        return

    _LOGGER.debug('%s(%s)=%s > off', entity_id, entity_attr, entity_value)
    with AsyncTrackStates(_hass) as changed_states:
        return await _hass.services.async_call(domain, 'turn_off', {'entity_id': entity_id}, True)
