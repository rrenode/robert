include karax / prelude
import karax/kdom except setInterval
import karax/vstyles
from sugar import `=>`

import std/[jsffi]

import shell

var rootShell: Shell = newShell("robert@renode")

var 
  curTyped = ""
  curCmdIndex: int = 0

proc createShellCursor(s: Shell): VNode =
  result = buildHtml(tdiv(class="command")):
    p:
      span(class="shell-prompt"):
        text s.user & ":" & s.cwd & "$ "

      input(
        class = "shell-input",
        `type` = "text",
        value = curTyped
      ):
        proc oninput(ev: Event, n: VNode) =
          curTyped = $InputElement(ev.target).value
          curCmdIndex = 0
        proc onkeyupenter(ev: Event, n: VNode) =
          if curTyped.len != 0:
            s.dispatchCommandShell(curTyped)
            curTyped = ""
        proc onkeydown(ev: Event, n: VNode) =
          let kev = KeyboardEvent(ev)
          echo curCmdIndex
          case kev.key
          of "ArrowUp":
            curCmdIndex += 1
            if curCmdIndex > s.prevCmdsBuffer.len:
              curCmdIndex -= 1
              return
            curTyped = s.prevCmdsBuffer[^curCmdIndex].text
          of "ArrowDown":
            if curCmdIndex > 1:
              curCmdIndex -= 1
              curTyped = s.prevCmdsBuffer[^curCmdIndex].text
            else:
              curCmdIndex = 0
              curTyped = ""
          of "Escape":
            curCmdIndex = 0
            curTyped = ""
          else: discard
    tdiv(class="command-output")

proc renderCommand(s: Shell, d: ShellOutput): VNode =
  result = buildHtml(tdiv(class="command")):
    p:
      span(class="shell-prompt"):
        text s.user & ":" & d.pwd & "$ "
      span:
        text d.text

proc renderInfo(s: Shell, d: ShellOutput): VNode =
  result = buildHtml(tdiv(class="command-output")):
    text d.text

proc renderOutput(s: Shell): VNode =
  result = buildHtml(tdiv):
    for res in s.outputBuffer:
      case res.kind
      of sokCommand:
        renderCommand(s, res)
      of sokStdout:
        discard
      of sokStderr:
        discard
      of sokInfo:
        renderInfo(s, res)

proc createDom: VNode =
  result = buildHtml(tdiv):
    canvas(id="bg")
    main():
      renderOutput(rootShell)
      createShellCursor(rootShell)

setRenderer createDom