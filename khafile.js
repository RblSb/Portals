let project = new Project('Portals');
project.addAssets('res/**', {
	nameBaseDir: 'res',
	destination: '{dir}/{name}',
	name: '{dir}/{name}'
});
project.addSources('src');
project.addDefine('khmProps=game.CustomData.TileProps');
//project.addDefine('debug');
//project.addParameter('-dce full');

resolve(project);
