DELETE FROM `command` WHERE `name` = 'peak';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
(
    'peak',
    3,
    'Syntax: .peak <class>\r\n\r\nRaises the current character to the maximum level, sets money to the supported maximum, learns class spells and languages, resets talents and grants the normal free talent points, unlocks all 11 primary profession slots without learning professions or recipes, grants one ground and one flying mount, maximizes non-profession skills, and replaces all equippable gear with the highest available BiS profile. The class argument must match the character class. This command destroys existing equipped and equippable inventory items.'
);
