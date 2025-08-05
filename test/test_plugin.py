import pynvim
import pytest
import utils
import time
import os


@pytest.fixture
def nvim():
    utils.init_env()

    nvim = pynvim.attach(
        'child', argv=["nvim", "--headless", "--embed"])
    yield nvim
    nvim.close()
    utils.clean()


def test_command(nvim):
    """
    Test command :UnnestEdit
    """
    winid = nvim.api.get_current_win()

    nvim.command('UnnestEdit nvim Xtest/tmp/test_command.txt')
    time.sleep(0.5)

    # job must have been closed
    job = nvim.current.window.vars['unnest_chan']
    with pytest.raises(pynvim.api.common.NvimError) as err_info:
        nvim.funcs.jobpid(job)
    assert "Invalid channel id" in str(err_info.value)

    # Don't change window after running command
    assert winid == nvim.api.get_current_win()

    buftype = nvim.current.buffer.options['buftype']
    assert buftype == ''
    bufname = nvim.current.buffer.name
    assert bufname == os.path.join(
        os.getcwd(), 'Xtest', 'tmp', 'test_command.txt')


def test_winlayout(nvim):
    """
    Test winlayout when users use builtin terminal to open nested Nvim
    """
    tab = nvim.api.get_current_tabpage()

    winbuflayout = ['col',
                    [['row',
                      [['leaf', {
                          "name": os.path.abspath('README.md'),
                          "diff": True}],
                       ['leaf', {
                           "name": os.path.abspath('LICENSE'),
                           "diff": True}]]],
                     ['leaf', {
                         "name": os.path.abspath('.editorconfig'),
                         "diff": False}]]]
    nvim.command(
        'term nvim -d "README.md" "LICENSE" +"botright split .editorconfig" +"tcd Xtest"')
    time.sleep(0.5)

    # Must be in a new tab
    assert tab != nvim.api.get_current_tabpage()
    assert nvim.funcs.tabpagenr() == 2

    # the child Nvim hasn't been closed yet
    child = nvim.current.tabpage.vars['unnest_socket']
    assert nvim.funcs.sockconnect('pipe', child) != 0

    # cwd must be the same as in child Nvim
    assert nvim.funcs.getcwd(-1, 0) == os.path.join(os.getcwd(), 'Xtest')

    # winlayout must be the same as in child Nvim
    winlayout = nvim.funcs.winlayout()
    assert utils.winlayout_handle_winid(nvim, winlayout) == winbuflayout

    # Call :tabclose must close child Nvim, so sockconnect later must raise an
    # error
    nvim.command('tabclose')
    time.sleep(0.1)
    with pytest.raises(pynvim.api.common.NvimError) as connect_info:
        nvim.funcs.sockconnect('pipe', child)
    assert "connection failed: connection refused" in str(connect_info.value)
