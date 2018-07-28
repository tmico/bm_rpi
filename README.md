# bm_rpi
baremetal assembler on raspi B
A super basic kernel, if it can even be called that, writen for the 
rasberry pi B/zero in assemblear.

Inspired by and to begin with based on Alex Chadwick's excellent turorial: 
http://www.cl.cam.ac.uk/projects/raspberrypi/tutorials/os/index.html

This is a personal project to learn about assembly, the underlying hardware,
os development and programing in general 

As of yet it really doesn't do much other than blink an led using an interupt,
display some text and display a picture, send some text (GPU memmory address)
over serial (uart). A very rudimentry TLB to enable the mmu is also used 

Be warned: The code is probably of poor quality and the comments probably
more so. Ive tried to explain what the various bits and pieces do but but
how well is debateable!!! ;)
