import pynvim
import pytest
import time
import utils


@pytest.fixture
def nvim():
    utils.init_env()

    nvim = pynvim.attach(
        'child', argv=["nvim", "--clean", "--headless", "--embed"])
    yield nvim
    nvim.close()
    utils.clean()


def test_plugin(nvim):
    win = nvim.api.get_current_win()

    nvim.command('term nvim test_clean.txt')
    time.sleep(0.5)

    # Don't change window after running command
    assert win == nvim.api.get_current_win()

    buftype = nvim.current.buffer.options['buftype']
    assert buftype == 'terminal'
