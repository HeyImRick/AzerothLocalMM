DELETE FROM `command` WHERE `name` = 'peak';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
(
    'peak',
    3,
    'Syntax: .peak <class>\r\n\r\nRaises the current character to the maximum level, sets money to the supported maximum, learns all available class spells, talents, professions, recipes and languages, maximizes skills, and replaces all equippable gear with the highest available BiS profile. The class argument must match the character class. This command destroys existing equipped and equippable inventory items.'
);
