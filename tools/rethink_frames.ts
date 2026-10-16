// Prints what an upstream rethink driver sends and publishes, for expected values in ported
// tests. Copy into a rethink checkout's tests/ directory (it uses rethink's mocks), then run:
//   node --import tsx tests/rethink_frames.ts <modelId> [<frame hex> | <prop>=<value>] ...
// Arguments run in order on one device after start(). Each line shows what that step sent
// (packets, then other commands such as acks as cmd:hex) and, for frames, the properties.
import { MockHAConnection, MockThinq2Device, buf, hex } from '@/tests/helpers/mocks'

const [model, ...steps] = process.argv.slice(2)
const DUT = (await import(`@/cloud/devices/${model}`)).default
const meta = { modelId: model, modelName: model, swVersion: '1.0' }
const ha = new MockHAConnection()
const thinq = new MockThinq2Device('id', meta)
const dev = new DUT(ha.asConnection(), thinq, meta)

function step(label: string, run: () => void, props: boolean) {
    thinq.resetRecorder()
    run()
    const sent = [...thinq.outbox.map(hex), ...thinq.sent.map((m) => `${m.cmd}:${m.data}`)]
    const tail = props ? ' ' + JSON.stringify(ha.devices['id']?.properties ?? {}) : ''
    console.log(`${label} -> ${sent.join(' ')}${tail}`)
}

step('start', () => dev.start(), false)
for (const s of steps) {
    if (s.includes('=')) {
        const [prop, value] = s.split('=')
        step(s, () => dev.setProperty(prop, value), false)
    } else step(s.slice(0, 12), () => thinq.emit('data', buf(s)), true)
}
