#!/usr/bin/python3

###############################
###    IMPORT LIBRARIES     ###
###############################
import ElectricalDeviceClass
from Filters import LowPassFilter
import ControlBusClass

class ESC(ElectricalDeviceClass.ElectricalDeviceClass):
    '''Electronic speed controller for an induction motor'''
    # Takes in electrical power from battery and converts it to elec power for motor
    # Does not work in reverse to charge battery
    _ctrl_sig              = ControlBusClass.ControlBusClass('signed')
    i_max_to_motor         = None
    i_max_from_motor       = None
    _p_max                 = None
    _lpf                   = LowPassFilter(1)
    _electrical_efficiency = None
    _input_data            = ElectricalDeviceClass.ElectricalDeviceClass()


    ###############################
    ###     INITIALISATION      ###
    ###############################
    def __init__(self, kwargs):
        self.i_max_to_motor   = kwargs.get('motor_i_max')
        self.i_max_from_motor = kwargs.get('motor_i_max')
        self._p_max = kwargs.get('p_max')
        self._electrical_efficiency = kwargs.get('efficiency', 0.85)
        return super().__init__(kwargs)


    ###############################
    ###      UPDATE LOOP        ###
    ###############################
    def update(self, dt):
        super().update(dt)

        # This current value needs constraining to battery and motor realtime limits
        
        ### TODO ###


    ###############################
    ###        GETTERS          ###
    ###############################

    # Control signal
    @property
    def control_signal(self):
        return self._ctrl_sig.value


    ###############################
    ###        SETTERS          ###
    ###############################

    # Control signal
    @control_signal.setter
    def control_signal(self, value):
        self._ctrl_sig.value = value

    # Input power
    def set_input_power(self, availability_dict):
        self.voltage = availability_dict.get('voltage')

        current = 0.0
        if self._ctrl_sig.decimal >= 0.0:
            current = self._ctrl_sig.decimal * self.i_max_to_motor
            current = min(current, availability_dict.get('max_discharge'), self.i_max_to_motor)
        else:
            #current = 0.0
            current = self._ctrl_sig.decimal * self.i_max_from_motor
            current = max(current, availability_dict.get('max_charge'), self.i_max_from_motor)

        self.current = current


###############################
###############################
######       END         ######
###############################
###############################