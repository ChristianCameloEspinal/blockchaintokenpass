import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TicketNFTModule = buildModule("TicketNFTModule", (m) => {
  const deployer = m.getAccount(0);
  const contract = m.contract("TicketNFT",[deployer]);
  return { contract };
});

export default TicketNFTModule;
