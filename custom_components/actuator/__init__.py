
import time, datetime
import voluptuous as vol
import homeassistant.helpers.config_validation as cv

import logging
_LOGGER = logging.getLogger(__name__)


DOMAIN = 'actuator'

ACTUATE_SCHEMA = vol.Schema({
    vol.Required('sensor_id'): cv.string,
    vol.Optional('sensor_attr'): cv.string,
    vol.Required('sensor_values'): list,
    vol.Optional('alt_sensor_values'): list,
    vol.Optional('alt_time_range'): list,
    vol.Required('entity_id'): cv.string,
    vol.Optional('entity_attr'): cv.string,
    vol.Optional('service'): cv.string,
    vol.Optional('service_attr'): cv.string,
    vol.Required('entity_values'): list,
    vol.Optional('ignore_interval'): int,
})

_hass = None
_stamps = {}

def setup(hass, config):
    global _hass
    _hass = hass
    hass.services.register(DOMAIN, 'actuate', actuate, schema=ACTUATE_SCHEMA)
    return True

def actuate(call):
    call_data = call.data

    entity_id = call_data.get('entity_id')
    entity_attr = call_data.get('entity_attr')
    service_attr = call_data.get('service_attr') or entity_attr

    ignore_interval = call_data.get('ignore_interval')
    if ignore_interval is None:
        ignore_interval = 180
    if ignore_interval > 0:
        global _stamps
        now = int(time.time())
        stamp = entity_id + '~' + service_attr
        if stamp in _stamps and now - _stamps[stamp] < ignore_interval:
            #_LOGGER.debug('%s ignored', stamp)
            return
        _stamps[stamp] = now

    sensor_id = call_data.get('sensor_id')
    sensor_attr = call_data.get('sensor_attr')
    alt_time_range = call_data.get('alt_time_range') or [20, 8]

    hour = datetime.datetime.now().hour
    if alt_time_range[1] > alt_time_range[0]:
        alt_time = hour > alt_time_range[0] and hour < alt_time_range[1]
    else:
        alt_time = hour > alt_time_range[0] or hour < alt_time_range[1]
    sensor_values = call_data.get('alt_sensor_values' if alt_time and 'alt_sensor_values' in call_data else 'sensor_values')

    service = call_data.get('service') or 'set_' + service_attr
    entity_values = call_data.get('entity_values')
    domain = entity_id[:entity_id.find('.')]

    sensor_state = _hass.states.get(sensor_id)
    sensor_attributes = sensor_state.attributes
    try:
        sensor_value = sensor_state.state if sensor_attr is None else sensor_attributes.get(sensor_attr)
    except AttributeError:
        _LOGGER.error("Sensor %s %s error", sensor_id, sensor_attr or '')
        return
    try:
        sensor_number = float(sensor_value)
    except ValueError:
        _LOGGER.error("Sensor %s %s Value %s error", sensor_id, sensor_attr or '', sensor_value)
        return

    sensor_name = sensor_attributes.get('friendly_name')
    sensor_log = sensor_name
    if sensor_attr:
         sensor_log += '.' + sensor_attr
    sensor_log += '=' + str(sensor_value)

    state = _hass.states.get(entity_id)
    if state is None:
        _LOGGER.error("Entity %s error", sensor_id)
        return

    state_value = state.state
    state_attributes = state.attributes
    friendly_name = state_attributes.get('friendly_name')

    i = len(sensor_values) - 1
    while i >= 0:
        if sensor_number >= sensor_values[i]:
            from_value = state_value if entity_attr is None else state_attributes.get(entity_attr)
            to_value = entity_values[i]

            entity_log = friendly_name
            if entity_attr:
                entity_log += '~' + entity_attr
            entity_log += '=' + str(from_value)

            if state_value == 'off':
                entity_log += ' ->on'
                _hass.services.call(domain, 'turn_on', {'entity_id': entity_id}, True)

            if from_value == to_value:
                _LOGGER.debug('%s, %s not changed', sensor_log, entity_log)
                return

            data = {'entity_id': entity_id, service_attr or entity_attr: to_value}
            _LOGGER.warn('%s, %s %s=>%s', sensor_log, entity_log, service, to_value)
            _hass.services.call(domain, service, data, True)
            return
        else:
            i = i - 1

    if state_value == 'off':
        _LOGGER.debug('%s, %s already off', sensor_log, friendly_name)
        return

    _LOGGER.warn('%s, %s=%s ->off', sensor_log, friendly_name, state_value)
    _hass.services.call(domain, 'turn_off', {'entity_id': entity_id}, True)
