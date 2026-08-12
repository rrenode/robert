include karax / prelude
import karax/kdom except setInterval
import karax/vstyles
from sugar import `=>`

import fs


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

let root = FsDir(name: "/")
root.addChild(
  FsFile(name: "whoami", executable: true, execProc:cmdWhoami)
)

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
          echo "PRESSED"
    tdiv(class="command-output")
    

proc createDom: VNode =
  result = buildHtml(tdiv):
    canvas(id="bg")
    main():
      newCommandView("whoami", cmdWhoami())
      createShellCursor()

    
setRenderer createDom