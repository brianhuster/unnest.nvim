import pynvim
import pytest
import time
import utils


@pytest.fixture
def vim():
    utils.init_env()

    vim = pynvim.attach(
        'child', argv=["nvim", "--clean", "--headless", "--embed"])
    yield vim
    vim.close()
    utils.clean()


def test_plugin(vim):
    win = vim.current.window

    vim.command('term nvim test_clean.txt')
    time.sleep(0.2)

    # Don't change window after running command
    assert win == vim.current.window

    # The buffer is still terminal
    assert vim.current.buffer.options['buftype'] == 'terminal'
