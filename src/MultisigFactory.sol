// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./HackathonCompany.sol";
import "./interfaces/ICompanyHackathon.sol";
contract HackathonFactory {
    ICompanyHackathon hackathon;
    struct HackathonStruct {
        uint256 _hackathonIndex;
        address _contract;
    }
    event gotHackathons(address[] hackathons);
    mapping(uint256 => HackathonStruct) public allHackathon;
    uint256 public numHackathons;

    function createHackathon(string memory _hackathonName, uint256 _deposit, address _priceFeed)
        public
    {
        HackathonCompany hackathon = new HackathonCompany(_hackathonName, _deposit, msg.sender, _priceFeed);
        allHackathon[numHackathons] = HackathonStruct(numHackathons, address(hackathon));
        console.log("New hackathon deployed at", address(hackathon));
        numHackathons++;
    }

    function getHackathonDetails(uint256 _hackathonIndex)
        public
        view
        returns (HackathonStruct memory)
    {
        return allHackathon[_hackathonIndex];
    }

    function checkIfUserIsJudge(address _hackathonAddress, address _judgeAddress) public returns (bool){
        hackathon = ICompanyHackathon(_hackathonAddress);
        return hackathon.isJudge(_judgeAddress);
    }

    function getHackathonsWhereUserIsJudge(address _address) public returns (address[] memory) {
        address[] memory hackathons = new address[](numHackathons);
        for(uint i = 0; i < numHackathons; i++) {
            bool isJudge = checkIfUserIsJudge(allHackathon[i]._contract, _address);
            if (isJudge) {
                hackathons[i] = allHackathon[i]._contract;
            }
        }
        emit gotHackathons(hackathons);
        return hackathons;
    }
}
