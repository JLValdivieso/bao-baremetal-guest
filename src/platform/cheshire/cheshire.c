#include <uart.h>
#include <8250_uart.h>

#define CHESHIRE_UART_ADDR       0x03002000
#define CHESHIRE_UART_FREQ       50000000
#define CHESHIRE_UART_BAUDRATE   115200
#define CHESHIRE_UART_REG_SHIFT  2
#define CHESHIRE_UART_REG_WIDTH  4

void uart_init(void)
{
    uart8250_init(CHESHIRE_UART_ADDR,
                  CHESHIRE_UART_FREQ,
                  CHESHIRE_UART_BAUDRATE,
                  CHESHIRE_UART_REG_SHIFT,
                  CHESHIRE_UART_REG_WIDTH);
}

void uart_putc(char c)
{
    uart8250_putc(c);
}

char uart_getchar(void)
{
    return uart8250_getc();
}

void uart_enable_rxirq(void)
{
    uart8250_enable_rx_int();
}

void uart_clear_rxirq(void)
{
    uart8250_interrupt_handler();
}
