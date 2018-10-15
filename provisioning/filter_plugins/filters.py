import yaml

class FilterModule(object):
    def filters(self):
        return {
            'named_volumes': self.named_volumes,
            'volume': self.volume,
            'volume_source': self.volume_source
        }

    def named_volumes(self, volumes):
        named_vols = []
        for vol in volumes:
            if vol['type'] not in ["mount-dir", "bind"]:
                named_vols.append(vol)

        return named_vols

    def volume_source(self, volumes, name, mount_dir):
        vol = self.volume(volumes, name)

        if vol['type'] == "mount-dir":
            return "{0}/{1}".format(mount_dir, vol['name'])
        elif vol['type'] == "bind":
            return vol['source']
        else:
            # otherwise it is some sort of named volume
            return vol['name']

    def volume(self, volumes, name):
        for vol in volumes:
            if vol['name'] == name:
                return vol

        raise ValueError('Volume with name "{0}" does not exist'.format(vol['name']))
