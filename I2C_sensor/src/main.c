#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
/* Include the header file of the I2C API */
#include <zephyr/drivers/i2c.h>
#include <zephyr/logging/log.h>
/*Include header to gpios and UART*/
#include <zephyr/drivers/gpio.h>
#include <zephyr/drivers/uart.h>
#include <zephyr/sys/printk.h>

/*Enable logging*/
LOG_MODULE_REGISTER(BMP280, LOG_LEVEL_DBG);

#define SLEEP_TIME_MS 1000

/* Define the I2C slave device address and the addresses of relevant registers */
#define CTRLMEAS 0xF4
#define CALIB00	 0x88
#define ID	     0xD0
#define TEMPMSB	 0xFA
#define PRESSMSB 0xF7
#define CHIP_ID  0x58
#define SENSOR_CONFIG_VALUE 0x93

/* Get the node identifier of the sensor */
#define I2C_NODE DT_NODELABEL(bme280)
/* Data structure to store BME280 data */
struct bme280_data {
	/* Compensation parameters */
	uint16_t dig_t1;
	int16_t dig_t2;
	int16_t dig_t3;
	uint16_t dig_p1;
	int16_t dig_px[8];
} bmedata;


void bme_calibrationdata(const struct i2c_dt_spec *spec, struct bme280_data *sensor_data_ptr)
{
	uint8_t t_values[6];


	int ret = i2c_burst_read_dt(spec, CALIB00, t_values, 6);

	if (ret != 0) {
		LOG_ERR("Failed to read register %x \n", CALIB00);
		return;
	}
	sensor_data_ptr->dig_t1 = ((uint16_t)t_values[1]) << 8 | t_values[0];
	sensor_data_ptr->dig_t2 = ((uint16_t)t_values[3]) << 8 | t_values[2];
	sensor_data_ptr->dig_t3 = ((uint16_t)t_values[5]) << 8 | t_values[4];

	uint8_t p_values[18];

	ret = i2c_burst_read_dt(spec, CALIB00 + 6, p_values, 18);

	if (ret != 0) {
		LOG_ERR("Failed to read register %x \n", CALIB00 + 6);
		return;
	}
	sensor_data_ptr->dig_p1 = ((uint16_t)(p_values[1]) << 8 | p_values[0]);
	for (int i = 0; i < 8; i++) {
		sensor_data_ptr->dig_px[i] = ((int16_t)(p_values[3 + i * 2]) << 8 | p_values[2 + i * 2]);
	}

}

static int32_t bme280_compensate_temp(struct bme280_data *data, int32_t adc_temp)
{
	int32_t var1, var2, t_fine;

	var1 = (((adc_temp >> 3) - ((int32_t)data->dig_t1 << 1)) * ((int32_t)data->dig_t2)) >> 11;

	var2 = (((((adc_temp >> 4) - ((int32_t)data->dig_t1)) *
		  ((adc_temp >> 4) - ((int32_t)data->dig_t1))) >> 12) *
		((int32_t)data->dig_t3)) >> 14;

	t_fine = var1 + var2;
	return t_fine;
}

static int32_t read_and_print_temp(const struct i2c_dt_spec *spec, struct bme280_data *data)
{
	uint8_t temp_raw[3];
	int ret = i2c_burst_read_dt(spec, TEMPMSB, temp_raw, 3);

	if (ret != 0) {
		LOG_ERR("Failed to read register %x \n", TEMPMSB);
		return 0;
	}
	int32_t adc_temp = ((int32_t)temp_raw[0] << 12) | ((int32_t)temp_raw[1] << 4) | (temp_raw[2] >> 4);
	int32_t t_fine = bme280_compensate_temp(data, adc_temp); //compensate temprature
	int32_t temp = (t_fine * 5 + 128) >> 8;
	LOG_INF("Temperature: %d.%02d °C\n", temp / 100, temp % 100);
	printk("Temperature: %d.%02d °C\n", temp / 100, temp % 100);

	return t_fine;
}

static uint32_t bme280_compensate_pres(struct bme280_data *data, int32_t adc_pres, int32_t t_fine)
{
	int64_t var1, var2, p;

	var1 = ((int64_t)t_fine) - 128000;
	var2 = var1 * var1 * (int64_t)data->dig_px[4];
	var2 = var2 + ((var1 * (int64_t)data->dig_px[3]) << 17);
	var2 = var2 + (((int64_t)data->dig_px[2]) << 35);
	var1 = ((var1 * var1 * (int64_t)data->dig_px[1]) >> 8) + ((var1 * (int64_t)data->dig_px[0]) << 12);
	var1 = (((((int64_t)1) << 47) + var1)) * ((int64_t)data->dig_p1) >> 33;

	if (var1 == 0) {
		return 0; // avoid exception caused by division by zero
	}
	p = 1048576 - adc_pres;
	p = (((p << 31) - var2) * 3125) / var1;
	var1 = (((int64_t)data->dig_px[7]) * (p >> 13) * (p >> 13)) >> 25;
	var2 = (((int64_t)data->dig_px[6]) * p) >> 19;

	p = ((p + var1 + var2) >> 8) + (((int64_t)data->dig_px[5]) << 4);

	return (uint32_t)p;
}

void read_and_print_pressure(const struct i2c_dt_spec *spec, struct bme280_data *data, int32_t t_fine)
{
	uint8_t pres_raw[3];
	int ret = i2c_burst_read_dt(spec, PRESSMSB, pres_raw, 3);


	if (ret != 0) {
		LOG_ERR("Failed to read register %x \n", PRESSMSB);
		return;
	}
	int32_t adc_pres = ((int32_t)pres_raw[0] << 12) | ((int32_t)pres_raw[1] << 4) | (pres_raw[2] >> 4);


	uint32_t pressure = bme280_compensate_pres(data, adc_pres, t_fine); //compensate pressure
	pressure = pressure / 256;
	LOG_INF("Pressure: %d.%02d hPa\n", pressure / 100, pressure % 100);
	printk("Pressure: %d.%02d hPa\n", pressure / 100, pressure % 100);
}

int main(void)
{

	/* Retrieve the API-specific device structure and make sure that the device is
	 * ready to use  */
	static const struct i2c_dt_spec dev_i2c = I2C_DT_SPEC_GET(I2C_NODE);
	if (!device_is_ready(dev_i2c.bus)) {
		LOG_ERR("I2C bus %s is not ready!\n\r",dev_i2c.bus->name);
		return -1;
	}
	/* Verify it is proper device by reading device id  */
	uint8_t id = 0;
	uint8_t regs[] = {ID};

	int ret = i2c_write_read_dt(&dev_i2c, regs, 1, &id, 1);

	if (ret != 0) {
		LOG_ERR("Failed to read register %x \n", regs[0]);
		return -1;
	}

	if (id != CHIP_ID) {
		LOG_ERR("Invalid chip id! %x \n", id);
		return -1;
	}
	bme_calibrationdata(&dev_i2c, &bmedata);

	/* Setup the sensor by writing the value 0x93 to the Configuration register */
	//Pressure oversamling x8, Temperature oversampling x8, Normal mode
	uint8_t sensor_config[] = {CTRLMEAS, SENSOR_CONFIG_VALUE};

	ret = i2c_write_dt(&dev_i2c, sensor_config, 2);  //Write the configuration to the sensor

	if (ret != 0) {
		LOG_ERR("Failed to write register %x \n", sensor_config[0]);
		return -1;
	}

	printk("Program loaded");
	while (1) {

		int32_t t_fine = read_and_print_temp(&dev_i2c, &bmedata);

		read_and_print_pressure(&dev_i2c, &bmedata, t_fine);
		
		k_msleep(SLEEP_TIME_MS);
	}
}
