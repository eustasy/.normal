CREATE TABLE IF NOT EXISTS `Runonces` (
  `Runonce` varchar(128) NOT NULL,
  `Session` varchar(128) NOT NULL,
  `Active` int(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
