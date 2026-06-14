UPDATE `command`
SET `help` = 'Syntax: .revive [characterName]\r\n\r\nRevives the selected player, the named character, or yourself when no player is selected. From the worldserver console, use: revive <characterName>. Offline characters are revived on their next login.'
WHERE `name` = 'revive';
