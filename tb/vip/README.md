# Control PULP - Verification IPs

We employ proprietary verification IPs to simulate some I/O peripherals in RTL
environment using Mentor Questasim. Among them:

- I2C EEPROM: VIP to simulate I2C master peripheral
- SPI flash: VIP to simulate SPI master peripheral

They are currently employed for executing regression tests under `./tests/runtime-tests/peripherals`.
