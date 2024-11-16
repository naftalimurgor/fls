import { HardhatRuntimeEnvironment } from "hardhat/types";
import * as fs from "fs";
import * as path from 'path';



interface NetworkConfig {
  payToken: string;
  pythContract?: string;
  swapRouter?: string;
  [key: string]: string | undefined; // Allow other dynamic fields
}

export function getNetworkConfig(hre: HardhatRuntimeEnvironment): NetworkConfig {

  console.log("__dirname", __dirname)

  // Define the absolute path to the JSON file
  const configPath = __dirname + "/address_list.json";



  // Check if the file exists to prevent runtime errors
  if (!fs.existsSync(configPath)) {
    throw new Error(`Configuration file not found at path: ${configPath}`);
  }
  const networkConfig = JSON.parse(fs.readFileSync(configPath, "utf-8"));
  const currentNetwork = hre.network.name;

  const config = networkConfig[currentNetwork];
  if (!config) {
    throw new Error(`No deployment configuration found for network: ${currentNetwork}`);
  }

  return config;
}