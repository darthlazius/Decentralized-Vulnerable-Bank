import {buildModule} from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("BankModule", (m) => {
    const bank = m.contract("Bank");
      m.call(bank, "deposit", [], { value: 1n * 10n ** 18n });
    return {bank};
});