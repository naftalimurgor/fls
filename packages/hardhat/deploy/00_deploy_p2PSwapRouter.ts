import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployP2PSwapRouter: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  // Configuration values
  const admin = deployer; // Admin address for the router
  const onBehalfOf = deployer; // for testing its best to use the deployer address or an address that sends the ERC20 token for swapping

  console.log("Deploying P2PSwapRouter...");

  const deployment = await deploy("P2PSwapRouter", {
    from: deployer,
    args: [onBehalfOf, admin], // Constructor arguments
    log: true,
    autoMine: true, // Automatically mine the deployment transaction if on a local network
  });

  console.log("P2PSwapRouter deployed to:", deployment.address);
};

export default deployP2PSwapRouter;

deployP2PSwapRouter.tags = ["P2PSwapRouter"];