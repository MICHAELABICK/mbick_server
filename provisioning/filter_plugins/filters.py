import yaml

class FilterModule(object):
    def filters(self):
        return {
            'volume': self.volume,
            'volume_source': self.volume_source
        }

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
