
import datetime
import voluptuous as vol
import homeassistant.helpers.config_validation as cv

import logging
_LOGGER = logging.getLogger(__name__)


DOMAIN = 'actuator'

ACTUATE_SCHEMA = vol.Schema({
    vol.Required('sensor_id'): cv.string,
    vol.Optional('sensor_attr'): cv.string,
    vol.Required('sensor_values'): list,
    vol.Optional('sensor_values_alt'): list,
    vol.Required('entity_id'): cv.string,
    vol.Optional('entity_attr'): cv.string,
    vol.Optional('service'): cv.string,
    vol.Optional('service_attr'): cv.string,
    vol.Required('entity_values'): list,
})

_hass = None

def setup(hass, config):
    global _hass
    _hass = hass
    hass.services.register(DOMAIN, 'actuate', actuate, schema=ACTUATE_SCHEMA)
    return True

def actuate(call):
    call_data = call.data
    now = datetime.datetime.now().hour
    sensor_id = call_data.get('sensor_id')
    sensor_attr = call_data.get('sensor_attr')
    sensor_values = call_data.get('sensor_values_alt' if now > 2 and now < 7 and 'sensor_values_alt' in call_data else 'sensor_values')

    entity_id = call_data.get('entity_id')
    entity_attr = call_data.get('entity_attr')
    service_attr = call_data.get('service_attr')
    service = call_data.get('service') or 'set_' + (service_attr or entity_attr)
    entity_values = call_data.get('entity_values')
    domain = entity_id[:entity_id.find('.')]

    sensor_state = _hass.states.get(sensor_id)
    try:
        sensor_value = sensor_state.state if sensor_attr is None else sensor_state.attributes.get(sensor_attr)
    except AttributeError:
        _LOGGER.error("Sensor %s %s error", sensor_id, sensor_attr or '')
        return
    try:
        sensor_value = float(sensor_value)
    except ValueError:
        _LOGGER.error("Sensor %s %s Value %s error", sensor_id, sensor_attr or '', sensor_value)
        return
    _LOGGER.debug("%s %s= %s", sensor_id, sensor_attr or '', sensor_value)

    state = _hass.states.get(entity_id)
    state_value = state.state
    state_attributes = state.attributes
    friendly_name = state_attributes.get('friendly_name')

    i = len(sensor_values) - 1
    while i >= 0:
        if sensor_value >= sensor_values[i]:
            if state_value == 'off':
                _hass.services.call(domain, 'turn_on', {'entity_id': entity_id}, True)

            to_value = entity_values[i]
            current_value = state_value if entity_attr is None else state_attributes.get(entity_attr)
            if current_value == to_value:
                _LOGGER.debug('%s %s %s= %s not changed', friendly_name, entity_id, entity_attr or '', current_value)
                return

            data = {'entity_id': entity_id, service_attr or entity_attr: to_value}
            _LOGGER.info('%s %s %s= %s -%s> %s', friendly_name, entity_id, entity_attr or '', current_value, service, to_value)
            _hass.services.call(domain, service, data, True)
            return
        else:
            i = i - 1

    if state_value == 'off':
        _LOGGER.debug('%s %s %s is already off', friendly_name, entity_id, entity_attr or '')
        return

    _LOGGER.info('%s %s %s= %s -> off', friendly_name, entity_id, entity_attr or '', state_value)
    _hass.services.call(domain, 'turn_off', {'entity_id': entity_id}, True)
