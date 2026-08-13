include karax / prelude
import karax/kdom except setInterval
import karax/vstyles
from sugar import `=>`

import std/parseopt
import std/os


import shell

var rootShell: Shell = newShell("robert@renode")

proc cmdWhoami(args: seq[string] = @[]): VNode =
  result = buildHtml(tdiv):
    h1:
      text "Robert J Renode IV"
    h2:
      text "|-> Software Dev"
    h2:
      text "|-> Need something!"
    h2:
      text "|-> Math & Music Tutor"

proc newCommandView(input: string, output: VNode): VNode =
  result = buildHtml(tdiv(class="command")):
    p:
      span(class="shell-prompt"):
        text "robert@renode:~$"
      span:
        text " " & input
    tdiv(class="command-output"):
      output

var curTyped = ""

proc createShellCursor: VNode =
  result = buildHtml(tdiv(class="command")):
    p:
      span(class="shell-prompt"):
        text "robert@renode:~$ "

      input(
        class = "shell-input",
        `type` = "text",
        value = curTyped
      ):
        proc oninput(ev: Event, n: VNode) =
          curTyped = $InputElement(ev.target).value
        proc onkeyupenter(ev: Event, n: VNode) =
          if curTyped.len != 0:
            rootShell.dispatchCommandShell(curTyped)
            curTyped = ""
    tdiv(class="command-output")

proc renderCommand(s: Shell, d: ShellOutput): VNode =
  result = buildHtml(tdiv(class="command")):
    p:
      span(class="shell-prompt"):
        text "robert@renode:~$ "
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
      #newCommandView("whoami", cmdWhoami())
      renderOutput(rootShell)
      createShellCursor()

    
setRenderer createDom