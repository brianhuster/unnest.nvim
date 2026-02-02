import pynvim
from pynvim import Nvim
import pytest
import utils
import time
import os
from os.path import abspath
from dataclasses import dataclass
from typing import Optional


@pytest.fixture
def vim():
    utils.init_env()
    vim = pynvim.attach(
        'child', argv=["nvim", "--headless", "--embed"])

    yield vim

    vim.close()
    utils.clean()


def test_command(vim: Nvim):
    """
    Test command :UnnestEdit
    """
    first_win = vim.current.window

    vim.command('UnnestEdit nvim Xtest/tmp/test_command.txt')
    time.sleep(0.2)

    cur_win = vim.current.window

    # The window must not change after running the command
    assert first_win == cur_win

    # job must have been closed
    job = cur_win.vars['unnest_chan']
    with pytest.raises(pynvim.api.common.NvimError) as err_info:
        vim.funcs.jobpid(job)
    assert "Invalid channel id" in str(err_info.value)

    cur_buf = vim.current.buffer
    assert cur_buf.options['buftype'] == ''
    assert cur_buf.name == os.path.join(
        os.getcwd(), 'Xtest', 'tmp', 'test_command.txt')


@dataclass
class WinlayoutExpected:
    winbuflayout: list
    cwd: Optional[str] = None


@pytest.mark.parametrize("cmd, expected", [
    (
        'term nvim -d "README.md" "LICENSE" +"botright split .editorconfig" +"tcd Xtest"',
        WinlayoutExpected(
            winbuflayout=['col',
                          [['row',
                            [['leaf', {
                                "name": abspath('README.md'),
                                "diff": True}],
                             ['leaf', {
                                 "name": abspath('LICENSE'),
                                 "diff": True}]]],
                           ['leaf', {
                               "name": abspath('.editorconfig'),
                               }]]],
            cwd=os.path.join(os.getcwd(), 'Xtest')
        )
    ),
    (
        'term nvim file1.txt +"split file2.txt" +"botright vsplit file3.txt" +"split file4.txt" +"botright vsplit file5.txt"',
        WinlayoutExpected(
            winbuflayout=['row',
                          [['col',
                            [['leaf', {
                                "name": abspath('file2.txt'),
                                }],
                             ['leaf', {
                                 "name": abspath('file1.txt'),
                                 }]]],
                           ['col',
                            [['leaf', {
                                "name": abspath('file4.txt'),
                                }],
                             ['leaf', {
                                 "name": abspath('file3.txt'),
                                 }]]],
                           ['leaf', {
                               "name": abspath('file5.txt'),
                               }]]]
        )
    )
])
def test_winlayout(vim: Nvim, cmd: str, expected: WinlayoutExpected):
    """
    Test winlayout when users use builtin terminal to open nested Nvim
    """
    first_tab = vim.current.tabpage

    vim.command(cmd)
    time.sleep(0.2)

    # Must be in a new tabpage now
    cur_tab = vim.current.tabpage
    assert first_tab != cur_tab
    assert cur_tab.number == 2

    # the child Nvim hasn't been closed yet
    child = cur_tab.vars['unnest_socket']
    assert vim.funcs.sockconnect('pipe', child) != 0

    # cwd must be the same as in child Nvim
    assert vim.funcs.getcwd(-1, 0) == expected.cwd or os.getcwd()

    # winlayout must be the same as in child Nvim
    winlayout = vim.funcs.winlayout()
    assert utils.winlayout_handle_winid(
        vim, winlayout) == expected.winbuflayout

    # Call :tabclose must close child Nvim, so sockconnect later must raise an
    # error
    vim.command('tabclose')
    time.sleep(0.1)
    with pytest.raises(pynvim.api.common.NvimError) as connect_info:
        vim.funcs.sockconnect('pipe', child)
    assert "connection failed: connection refused" in str(connect_info.value)
