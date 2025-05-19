# axi_apb_i2c_slave
This is the I2C slave used in the PULP Control project.

Limitation:
- only write from master
- The master does not specify the starting address.
- The master sends an MCTP packet. 
- The I2C slave copies the MCTP data into L2. The starting address is 0x1axx_xxxx. You can change the start address by writing to the I2C control register YY via APB bus 
