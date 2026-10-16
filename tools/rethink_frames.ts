// Prints the exact frames an upstream rethink driver sends, for expected values in ported tests.
// Copy into a rethink checkout's tests/ directory (it uses rethink's mocks), then run there:
//   node --import tsx tests/rethink_frames.ts <modelId> [<frame hex>,...] [<prop>=<value> ...]
// Prints the start() frames, one line per command, then the published properties.
import { MockHAConnection, MockThinq2Device, buf, hex } from '@/tests/helpers/mocks'

const [model, frames, ...commands] = process.argv.slice(2)
const DUT = (await import(`@/cloud/devices/${model}`)).default
const meta = { modelId: model, modelName: model, swVersion: '1.0' }
const ha = new MockHAConnection()
const thinq = new MockThinq2Device('id', meta)
const dev = new DUT(ha.asConnection(), thinq, meta)
thinq.resetRecorder()
dev.start()
console.log('start', thinq.outbox.map(hex).join(' '))
if (frames) for (const frame of frames.split(',')) thinq.emit('data', buf(frame))
for (const command of commands) {
    const [prop, value] = command.split('=')
    thinq.resetRecorder()
    dev.setProperty(prop, value)
    console.log(command, thinq.outbox.map(hex).join(' '))
}
console.log('props', JSON.stringify(ha.devices['id']?.properties))
