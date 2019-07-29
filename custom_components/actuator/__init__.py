
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
    sensor_id = call.data.get('sensor_id')
    sensor_attr = call.data.get('sensor_attr')
    sensor_values = call.data.get('sensor_values')

    entity_id = call.data.get('entity_id')
    entity_attr = call.data.get('entity_attr')
    service = call.data.get('service')
    service_attr = call.data.get('service_attr')
    entity_values = call.data.get('entity_values')
    domain = entity_id[:entity_id.find('.')]

    sensor_state = _hass.states.get(sensor_id)
    if sensor_state is None:
        _LOGGER.error("No sensor state for %s", sensor_id)
        return

    sensor_value = float(sensor_state.state if sensor_attr is None else sensor_state.attributes.get(sensor_attr))
    _LOGGER.debug("%s %s= %s", sensor_id, sensor_attr or '', sensor_value)

    state = _hass.states.get(entity_id)
    state_value = state.state

    i = len(sensor_values) - 1
    while i >= 0:
        if sensor_value >= sensor_values[i]:
            to_value = entity_values[i]
            current_value = state_value if entity_attr is None else state.attributes.get(entity_attr)
            if current_value == to_value:
                _LOGGER.debug('%s %s= %s not changed', entity_id, entity_attr or '', current_value)
                return

            data = {'entity_id': entity_id, service_attr or entity_attr: to_value}
            _LOGGER.info('%s %s= %s > %s, %s %s', entity_id, entity_attr or '', current_value, to_value, service, data)
            _hass.services.call(domain, service or 'set_' + entity_attr, data, True)
            return
        else:
            i = i - 1

    if state_value == 'off':
        _LOGGER.debug('%s %s is already off', entity_id, entity_attr or '')
        return

    _LOGGER.info('%s %s= %s > off', entity_id, entity_attr or '', state_value)
    _hass.services.call(domain, 'turn_off', {'entity_id': entity_id}, True)
