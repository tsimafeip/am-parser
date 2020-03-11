
import asyncio


async def tcp_echo_client(message, loop):
    reader, writer = await asyncio.open_connection('127.0.0.1', 8888,
                                                   loop=loop)
    print('Send: %r' % message)
    writer.write(message.encode())

    data = await reader.read(40_000)
    print('Received: %r' % data.decode())

    print('Close the socket')
    writer.close()


message = """
{
	"sentence": "the boy wants to sleep.",
	"formats": ["AMR-2017", "EDS"]
}
"""
loop = asyncio.get_event_loop()
loop.run_until_complete(tcp_echo_client(message, loop))
loop.close()
