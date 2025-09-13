# Bash Scripts

A collection of useful Bash scripts for setup and customization.  
You can run each script directly using `curl ... | bash`.

---

## Available Scripts

| Script Name       | Description                                                   | Command                                                                                                                                  |
|-------------------|---------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| tmux.sh           | Install and configure Tmux with custom settings               | <code>curl -fsSL https://raw.githubusercontent.com/Omcodes23/Bash-Scripts/main/tmux.sh \| bash</code>                                     |
| dock-3.sh          | Setup Dokage , Docker, and Portainer                       | <code>curl -fsSL https://raw.githubusercontent.com/Omcodes23/Bash-Scripts/main/dock-3.sh \| bash</code>                                   |
| terminal-name.sh  | Customize/change your terminal name (append desired name)     | <code>curl -fsSL https://raw.githubusercontent.com/Omcodes23/Bash-Scripts/main/terminal-name.sh \| bash -s omega</code>               |

---

## Example

To set your terminal name to **omega**:

```bash
curl -fsSL https://raw.githubusercontent.com/Omcodes23/Bash-Scripts/main/terminal-name.sh | bash -s omega
