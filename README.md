# Driving A Servo
Building off of the `fpga-pmodals` project, we'll use the code taking 
readings from the light-sensor and use that to drive a servo. The idea here is
to form a rudimentary building block for robotic interaction with the world.
Sensor information in, kinetic motion out.

Here it is in action: https://www.youtube.com/shorts/lxl4x09gqZM

Code is strictly (System)Verilog and should be FPGA agnostic, no proprietary IP.
Test benches are included. Tested using Vivado 2024.2.

Thanks to @suoglu for providing some nice Verilog interfaces to Digilent Pmods
that I was able to learn from, fork and use for this project. Especially since
Digilent [IP support ended after Vivado 2019.1](https://digilent.com/reference/learn/programmable-logic/tutorials/pmod-ips/start)

## Hardware
* Basys3 Board
* PmodALS Peripheral
* PmodCON3 Peripheral
* MG90S Servo

## Dependencies
CON3 module from https://github.com/oppaus/fpga-pmod-suite, a fork from @suoglu

# Timing Adjustments
Because of the servo I was using, the CON3 library needed some modification to
support a pulse-width range larger than 1ms -- being extremely new to
FGPA/Verilog this was the only way I could reason how to work out the timing, a
more seasoned verlilog veteran might know a better way. I needed to expand the
range to be from 0.5ms to 2.5ms (2ms) to get the full 180° range for the servo.

The following diagram shows the adjustment to the PWM side-by-side, the `servo_v2`
track shows the expanded 2ms range compared with the 1ms just above it.

![Timing diagram comparing 1ms vs 2ms pulse-widths](img/timing-1ms-vs-2ms.png)

