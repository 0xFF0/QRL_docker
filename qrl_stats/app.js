/*
 * Copyright 2018 Excitable Aardvark <excitableaardvark@tutanota.de>
 *
 * Licensed under the 3-Clause BSD license. See LICENSE in the project root for
 * more information.
 */
 
const QrlNode = require("@theqrl/node-helpers")  //https://github.com/theQRL/node-helpers
const express = require('express')
const prometheus = require('prom-client')
const util = require('util')

const DAEMON_HOST = process.env.DAEMON_HOST || 'localhost'
const DAEMON_PORT = process.env.DAEMON_PORT || '19009'
const Gauge = prometheus.Gauge

const app = express()

const daemon = new QrlNode (DAEMON_HOST, DAEMON_PORT)

const getStatsQRL = () => {
  return new Promise((resolve, reject)=> {
      
      console.log("Getting stats from QRL node")

      daemon.connect().then(() => {
        console.log("Connected to node: " + daemon.connection) // true if connection successful
        
        daemon.api('GetStats', {'include_timeseries': true}).then((result) => {
        
          console.log("Got result, block height: " + result.node_info.block_height)
          resolve(result)
              
        })
		
        console.log("Disconnecting...")
        daemon.disconnect()
    })

  })
}



let getInfo = util.promisify(getStatsQRL);

const difficulty = new Gauge({ name: 'qrl_block_difficulty', help: 'Last block difficulty' })
const incomingConnections = new Gauge({ name: 'qrl_connections_incoming', help: 'Number of incoming connections' })
const hashPower = new Gauge({ name: 'qrl_hashPower', help: 'Hash power' })
const outgoingConnections = new Gauge({ name: 'qrl_connections_outgoing', help: 'Number of outgoing connections' })
const reward = new Gauge({ name: 'qrl_block_reward', help: 'Last block reward' })
const nodeUptime = new Gauge({ name: 'qrl_node_uptime', help: 'Node uptime' })
const block_time_mean = new Gauge({ name: 'qrl_block_time_mean', help: 'Current block time mean.' })
const height = new Gauge({ name: 'qrl_height', help: 'Current block height' })
const coinsEmitted = new Gauge({ name: 'qrl_coins_emitted', help: 'Coins emitted' })

	

app.get('/metrics', (req, res) => {
  console.log("Metrics requested.")
  Promise.all([
    getStatsQRL()
  ])
    .then(([info]) => {
      console.log("Got the node stats. Sending to prometheus.")
      blockTimeseriesSize = info.block_timeseries.length
      difficulty.set(Number(info.block_timeseries[blockTimeseriesSize-1].difficulty))
      incomingConnections.set(Number(info.node_info.num_connections))
      hashPower.set(Number(info.block_timeseries[blockTimeseriesSize-1].hash_power))
      outgoingConnections.set(Number(info.node_info.num_known_peers))
      reward.set(Number(info.block_last_reward / 1e9))
      nodeUptime.set(Number(info.node_info.uptime))
      block_time_mean.set(Number(info.block_time_mean))
      height.set(Number(info.node_info.block_height))
      coinsEmitted.set(Number(info.coins_emitted))

      res.end(prometheus.register.metrics())
    })
    .catch(e => {
      console.log(e)
    })
})

module.exports = app
