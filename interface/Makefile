# Makefile for the driver tests
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

.PHONY: all modules clean

FLAGS=-g -O3 -Wall
CFLAGS=$(FLAGS)
FFLAGS=$(FLAGS) -ffree-line-length-none -ffixed-line-length-none

FFLAGS2= -fPIC -shared



FC=gfortran-7
CC=gcc

all: controller_interface.so

sockets.o: sockets.c
	$(CC) $(CFLAGS) -c -o sockets.o sockets.c

fsockets.o: fsockets.f90
	$(FC) $(FFLAGS) -c $< -o $@

controller_interface.o: controller_interface.f90
	$(FC) $(FFLAGS2) -c $< -o $@

controller_interface.so: sockets.o fsockets.o controller_interface.o
	$(FC) $(FFLAGS2) -o controller_interface.so $^


clean:
	rm -f *.o *.mod *.x *.so
