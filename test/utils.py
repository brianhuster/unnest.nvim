import os
import shutil
import pynvim


def init_env():
    xdg_config_home = "Xtest/xdg/config"
    xdg_data_home = "Xtest/xdg/share"
    tmpdir = "Xtest/tmp"
    os.environ["XDG_CONFIG_HOME"] = xdg_config_home
    os.environ["XDG_DATA_HOME"] = xdg_data_home
    os.environ["TMPDIR"] = tmpdir

    # Unset $NVIM so that when you run tests inside Nvim terminal, it doesn't
    # make parent Nvim open a new tab
    if "NVIM" in os.environ:
        del os.environ["NVIM"]

    os.makedirs(tmpdir, exist_ok=True)
    os.makedirs(xdg_config_home + "/nvim", exist_ok=True)

    config_file = os.path.join(xdg_config_home, "nvim", "init.lua")
    with open(config_file, "w") as f:
        f.write(f"""
                vim.opt.rtp:prepend [[{os.path.abspath('.')}]]
                vim.v.testing = 1
        """)


def clean():
    shutil.rmtree("Xtest", ignore_errors=True)


def winlayout_handle_winid(nvim: pynvim.Nvim, winlayout):
    """
    Convert any winid in winlayout into is a dictionary like
    {name: bufname, diff: &l:diff}
    """
    if isinstance(winlayout, list):
        return [winlayout_handle_winid(nvim, w) for w in winlayout]
    elif isinstance(winlayout, (int, float)):
        result = {
            "name": nvim.api.buf_get_name(nvim.api.win_get_buf(winlayout))
        }
        if nvim.api.get_option_value("diff", {"win": winlayout}):
            result["diff"] = True
        return result
    else:
        return winlayout
