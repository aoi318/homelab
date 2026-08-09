import asyncio
import json
import logging
import os
import ssl
import urllib.error
import urllib.request

import discord
from discord.ext import commands

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

PVE_API_URL = os.environ["PVE_API_URL"].rstrip("/")
PVE_TOKEN_ID = os.environ["PVE_TOKEN_ID"]
PVE_TOKEN_SECRET = os.environ["PVE_TOKEN_SECRET"]
PVE_NODE = os.environ["PVE_NODE"]
PVE_VM_ID = os.environ["PVE_VM_ID"]
VERIFY_SSL = os.environ.get("PVE_VERIFY_SSL", "true").lower() == "true"


def pve_request(method: str, path: str) -> dict:
    request = urllib.request.Request(
        f"{PVE_API_URL}{path}",
        method=method,
        headers={"Authorization": f"PVEAPIToken={PVE_TOKEN_ID}={PVE_TOKEN_SECRET}"},
    )
    context = None if VERIFY_SSL else ssl._create_unverified_context()
    try:
        with urllib.request.urlopen(request, context=context, timeout=10) as response:
            return json.load(response)["data"]
    except urllib.error.HTTPError as error:
        logger.warning("PVE API request failed: %s %s", method, path)
        raise RuntimeError(f"PVE API error ({error.code})") from error
    except urllib.error.URLError as error:
        logger.warning("PVE API is unreachable: %s", error)
        raise RuntimeError("PVE APIへ接続できません") from error


async def pve_status() -> dict:
    return await asyncio.to_thread(
        pve_request, "GET", f"/nodes/{PVE_NODE}/qemu/{PVE_VM_ID}/status/current"
    )


async def pve_power(action: str) -> None:
    await asyncio.to_thread(
        pve_request, "POST", f"/nodes/{PVE_NODE}/qemu/{PVE_VM_ID}/status/{action}"
    )


async def wait_for_vm_state(expected_state: str, timeout_seconds: int = 300) -> bool:
    for _ in range(timeout_seconds // 2):
        if (await pve_status())["status"] == expected_state:
            return True
        await asyncio.sleep(2)
    return False


intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix="!", intents=intents)


@bot.event
async def on_ready() -> None:
    assert bot.user is not None
    logger.info("Logged in as %s (%s)", bot.user, bot.user.id)


@bot.command(name="status")
async def status_command(ctx: commands.Context) -> None:
    try:
        status = await pve_status()
    except RuntimeError as error:
        await ctx.send(f"状態を取得できません: {error}")
        return
    await ctx.send(f"game01 (VM {PVE_VM_ID}) は **{status['status']}** です。")


@bot.command(name="start")
async def start_command(ctx: commands.Context) -> None:
    try:
        if (await pve_status())["status"] == "running":
            await ctx.send("game01はすでに起動しています。")
            return
        await pve_power("start")
    except RuntimeError as error:
        await ctx.send(f"起動できません: {error}")
        return
    await ctx.send("game01の起動を要求しました。完了を待機します。")
    if await wait_for_vm_state("running"):
        await ctx.send("game01の起動が完了しました。")
    else:
        await ctx.send("game01の起動完了を5分待ちましたが確認できませんでした。PVEの状態を確認してください。")


@bot.command(name="stop")
async def stop_command(ctx: commands.Context) -> None:
    try:
        if (await pve_status())["status"] != "running":
            await ctx.send("game01は停止しています。")
            return
        await pve_power("shutdown")
    except RuntimeError as error:
        await ctx.send(f"停止できません: {error}")
        return
    await ctx.send("game01の正常停止を要求しました。完了を待機します。")
    if await wait_for_vm_state("stopped"):
        await ctx.send("game01の停止が完了しました。")
    else:
        await ctx.send("game01の停止完了を5分待ちましたが確認できませんでした。PVEの状態を確認してください。")


bot.run(os.environ["DISCORD_TOKEN"])
